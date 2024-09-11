// S3 Bucket
resource "aws_s3_bucket" "warehouse_bucket" {
  bucket = "buster-warehouse"
}

// VPC and Subnets
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name = "buster-warehouse-vpc"
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
    Project     = "buster-warehouse"
  }
}

// Security Group for Load Balancer
resource "aws_security_group" "lb_sg" {
  name_prefix = "buster-warehouse-lb-sg"
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
    Name    = "buster-warehouse-lb-sg"
    Project = "buster-warehouse"
  }
}

// Security Group for Frontend Nodes
resource "aws_security_group" "fe_sg" {
  name_prefix = "buster-warehouse-fe-sg"
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
    Name    = "buster-warehouse-fe-sg"
    Project = "buster-warehouse"
  }
}

// Security Group for Backend Nodes
resource "aws_security_group" "be_sg" {
  name_prefix = "buster-warehouse-be-sg"
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
    Name    = "buster-warehouse-be-sg"
    Project = "buster-warehouse"
  }
}

locals {
  node_groups = {
    fe_group = {
      instance_type = "t3.small"
      min_size      = 1
      max_size      = 1
      desired_size  = 1
      disk_size     = 200
    },
    be_group = {
      instance_type = "t3.small"
      min_size      = 1
      max_size      = 1
      desired_size  = 1
      disk_size     = 1000
    },
    lb_group = {
      instance_type = "t3.small"
      min_size      = 1
      max_size      = 1
      desired_size  = 1
      disk_size     = 20
    }
    postgresql_group = {
      instance_type = "t3.small"
      min_size      = 1
      max_size      = 1
      desired_size  = 1
      disk_size     = 20
    }
    iceberg_rest_group = {
      instance_type = "t3.small"
      min_size      = 1
      max_size      = 1
      desired_size  = 1
      disk_size     = 20
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.26.3"

  cluster_name    = "buster-warehouse-${var.cluster_name}"
  cluster_version = "1.22"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    for key, value in local.node_groups :
    key => {
      instance_types = [value.instance_type]
      min_size       = value.min_size
      max_size       = value.max_size
      desired_size   = value.desired_size
      disk_size      = value.disk_size

      labels = {
        NodeGroup = key
        NodeType  = value.instance_type
        Project   = "buster-warehouse"
      }

      tags = {
        NodeGroup = key
        Project   = "buster-warehouse"
      }

      vpc_security_group_ids = [
        key == "fe_group" ? aws_security_group.fe_sg.id :
        key == "be_group" ? aws_security_group.be_sg.id :
        aws_security_group.lb_sg.id
      ]
    }
  }

  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = aws_iam_role.eks_node_group_role.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ]

  # Add this line to shorten the IAM role name prefix
  iam_role_name = "eks-cluster-role"
}

resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

// Application Load Balancer
resource "aws_lb" "eks_alb" {
  name               = "buster-warehouse-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = module.vpc.public_subnets

  tags = {
    Name    = "buster-warehouse-alb"
    Project = "buster-warehouse"
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
  name     = "buster-warehouse-fe-tg"
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
    name = "buster-warehouse-deployment"
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
    Name    = "buster-warehouse-s3-endpoint"
    Project = "buster-warehouse"
  }
}

// Update S3 bucket policy to allow access from the VPC Endpoint
resource "aws_s3_bucket_policy" "allow_access_from_vpc" {
  bucket = aws_s3_bucket.warehouse_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Access-to-specific-VPC-only"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.warehouse_bucket.arn,
          "${aws_s3_bucket.warehouse_bucket.arn}/*",
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
  name       = "buster-warehouse-starrocks"
  repository = "https://starrocks.github.io/starrocks-kubernetes-operator"
  chart      = "starrocks-operator"
  namespace  = kubernetes_namespace.starrocks.metadata[0].name

  values = [
    file("../helm_values/starrocks.yaml")
  ]

  depends_on = [module.eks, kubernetes_namespace.starrocks]
}

// Create a namespace for StarRocks
resource "kubernetes_namespace" "starrocks" {
  metadata {
    name = "buster-warehouse-starrocks"
  }

  depends_on = [module.eks]
}

// Helm Release for PostgreSQL
resource "helm_release" "postgresql" {
  name       = "buster-warehouse-postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  namespace  = kubernetes_namespace.postgresql.metadata[0].name

  set {
    name  = "global.postgresql.auth.postgresPassword"
    value = var.postgres_password
  }

  set {
    name  = "primary.persistence.size"
    value = "10Gi"
  }

  depends_on = [module.eks, kubernetes_namespace.postgresql]
}

// Create a namespace for PostgreSQL
resource "kubernetes_namespace" "postgresql" {
  metadata {
    name = "buster-warehouse-postgresql"
  }

  depends_on = [module.eks]
}

// Helm Release for Iceberg REST
resource "helm_release" "iceberg_rest" {
  name       = "buster-warehouse-iceberg-rest"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "common"
  namespace  = kubernetes_namespace.iceberg_rest.metadata[0].name

  values = [
    <<-EOT
    replicaCount: 1
    image:
      repository: tabulario/iceberg-rest
      tag: latest
      pullPolicy: IfNotPresent
    service:
      type: ClusterIP
      port: 8181
    containerPort: 8181
    env:
      - name: AWS_ACCESS_KEY_ID
        valueFrom:
          secretKeyRef:
            name: aws-credentials
            key: aws-access-key-id
      - name: AWS_SECRET_ACCESS_KEY
        valueFrom:
          secretKeyRef:
            name: aws-credentials
            key: aws-secret-access-key
      - name: AWS_REGION
        value: "${var.region}"
      - name: CATALOG_WAREHOUSE
        value: "${aws_s3_bucket.warehouse_bucket.id}"
      - name: CATALOG_URI
        value: "jdbc:postgresql://${helm_release.postgresql.name}-postgresql.${kubernetes_namespace.postgresql.metadata[0].name}.svc.cluster.local:5432/postgres"
      - name: CATALOG_JDBC_USER
        value: "postgres"
      - name: CATALOG_JDBC_PASSWORD
        value: "${var.postgres_password}"
    EOT
  ]

  depends_on = [module.eks, kubernetes_namespace.iceberg_rest, helm_release.postgresql]
}

// Create a namespace for Iceberg REST
resource "kubernetes_namespace" "iceberg_rest" {
  metadata {
    name = "buster-warehouse-iceberg-rest"
  }

  depends_on = [module.eks]
}

// Helm Release for Nginx Ingress Controller
resource "helm_release" "nginx_ingress" {
  name       = "buster-warehouse-nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.nginx_ingress.metadata[0].name

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
    value = "true"
  }

  depends_on = [module.eks, kubernetes_namespace.nginx_ingress]
}

// Create a namespace for Nginx Ingress
resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = "buster-warehouse-nginx-ingress"
  }

  depends_on = [module.eks]
}