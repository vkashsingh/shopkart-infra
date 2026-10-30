# Input variables for infra-master.
# Declares deployment region, administrator CIDR, SSH key path, and instance type.

variable "aws_region" {
  description = "AWS region where the master machine and associated resources are deployed"
  type        = string
  default     = "ap-southeast-2"
}

variable "my_ip" {
  description = "IPv4 CIDR block authorized for SSH (22), Jenkins (8080), and SonarQube (9000) access (e.g. 203.0.113.50/32)"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.my_ip))
    error_message = "The my_ip variable must be a valid CIDR block (e.g., 203.0.113.50/32)."
  }
}

variable "public_key_path" {
  description = "File path to the OpenSSH public key file imported for EC2 SSH access"
  type        = string
  default     = "~/.ssh/shopkart-master.pub"
}

variable "instance_type" {
  description = "EC2 instance type used for the master CI/CD and tooling host"
  type        = string
  default     = "m7i-flex.large"
}
