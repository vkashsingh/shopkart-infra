variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "my_ip" {
  description = "CIDR block allowed for SSH, Jenkins, and SonarQube access (e.g. 203.0.113.50/32)"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.my_ip))
    error_message = "The my_ip variable must be a valid CIDR block (e.g., 203.0.113.50/32)."
  }
}

variable "public_key_path" {
  description = "Path to the SSH public key file for the master instance"
  type        = string
  default     = "~/.ssh/shopkart-master.pub"
}

variable "instance_type" {
  description = "EC2 instance type for the master machine"
  type        = string
  default     = "t3.large"
}

