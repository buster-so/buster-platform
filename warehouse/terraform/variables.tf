variable "region" {
  default = "us-west-1"
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

variable "postgres_password" {
  description = "password"
  type        = string
  sensitive   = true
}

// Add more variables as needed