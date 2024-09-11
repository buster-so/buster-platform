// S3 Bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-unique-bucket-name"
}

// VPC and Subnets
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name = "my-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  // Restrict access to specified CIDR blocks
  manage_default_network_acl = true
  default_network_acl_ingress = [
    {
      rule_no    = 100
      action     = "deny"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    },
  ]
  default_network_acl_egress = [
    {
      rule_no    = 100
      action     = "deny"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    },
  ]

  public_dedicated_network_acl  = true
  private_dedicated_network_acl = true

  public_inbound_acl_rules = [
    for i, cidr_block in var.allowed_cidr_blocks : {
      rule_number = 100 + i
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = cidr_block
    }
  ]

  public_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]

  private_inbound_acl_rules = [
    for i, cidr_block in var.allowed_cidr_blocks : {
      rule_number = 100 + i
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = cidr_block
    }
  ]

  private_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

// Security Group for Load Balancer
resource "aws_security_group" "lb_sg" {
  name_prefix = "eks-lb-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "eks-lb-sg"
  }
}

// Security Group for Frontend Nodes
resource "aws_security_group" "fe_sg" {
  name_prefix = "eks-fe-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 9030
    to_port         = 9030
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
    description     = "Allow traffic from LB to frontend on port 9030"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "eks-fe-sg"
  }
}

// Security Group for Backend Nodes
resource "aws_security_group" "be_sg" {
  name_prefix = "eks-be-sg"
  vpc_id      = module.vpc.vpc_id

  // Add rules as needed for backend communication

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "eks-be-sg"
  }
}

// EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.3"

  cluster_name    = var.cluster_name
  cluster_version = "1.22"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    for key, value in var.node_groups :
    key => {
      instance_types = [value.instance_type]
      min_size       = value.min_size
      max_size       = value.max_size
      desired_size   = value.desired_size
      disk_size      = value.disk_size

      labels = {
        NodeGroup = key
        NodeType  = value.instance_type
      }

      tags = {
        NodeGroup = key
      }

      vpc_security_group_ids = [
        key == "fe_group" ? aws_security_group.fe_sg.id :
        key == "be_group" ? aws_security_group.be_sg.id :
        aws_security_group.lb_sg.id
      ]
    }
  }
}

// Application Load Balancer
resource "aws_lb" "eks_alb" {
  name               = "eks-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = module.vpc.public_subnets

  tags = {
    Name = "eks-alb"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.eks_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fe_tg.arn
  }
}

resource "aws_lb_target_group" "fe_tg" {
  name     = "fe-tg"
  port     = 9030
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path                = "/"
    port                = 9030
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

// Auto-attach frontend instances to target group
resource "aws_autoscaling_attachment" "fe_asg_attachment" {
  autoscaling_group_name = module.eks.eks_managed_node_groups["fe_group"].node_group_autoscaling_group_names[0]
  lb_target_group_arn    = aws_lb_target_group.fe_tg.arn
}

// Kubernetes Deployment for Docker image
resource "kubernetes_deployment" "example" {
  metadata {
    name = "example-deployment"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "example"
      }
    }

    template {
      metadata {
        labels = {
          app = "example"
        }
      }

      spec {
        container {
          image = "your-docker-image:tag"
          name  = "example"
        }
      }
    }
  }
}

// S3 VPC Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.region}.s3"
  
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = {
    Name = "s3-endpoint"
  }
}

// Update S3 bucket policy to allow access from the VPC Endpoint
resource "aws_s3_bucket_policy" "allow_access_from_vpc" {
  bucket = aws_s3_bucket.my_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Access-to-specific-VPC-only"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.my_bucket.arn,
          "${aws_s3_bucket.my_bucket.arn}/*",
        ]
        Condition = {
          StringEquals = {
            "aws:sourceVpce" = aws_vpc_endpoint.s3.id
          }
        }
      }
    ]
  })
}

// Helm Release for StarRocks
resource "helm_release" "starrocks" {
  name       = "starrocks"
  repository = "https://starrocks.github.io/starrocks-kubernetes-operator"
  chart      = "starrocks-operator"
  namespace  = kubernetes_namespace.starrocks.metadata[0].name

  values = [
    file("${path.module}/default.yaml")
  ]

  depends_on = [module.eks, kubernetes_namespace.starrocks]
}

// Create a namespace for StarRocks
resource "kubernetes_namespace" "starrocks" {
  metadata {
    name = "starrocks"
  }

  depends_on = [module.eks]
}