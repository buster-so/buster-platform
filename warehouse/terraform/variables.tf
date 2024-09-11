variable "region" {
  default = "us-west-2"
}

variable "cluster_name" {
  default = "buster-warehouse"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks allowed to access the VPC"
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "node_groups" {
  description = "Map of EKS managed node group configurations"
  type = map(object({
    instance_type = string
    min_size      = number
    max_size      = number
    desired_size  = number
    disk_size     = number
  }))
  default = {
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

variable "postgres_password" {
  description = "password"
  type        = string
  sensitive   = true
}

// Add more variables as needed