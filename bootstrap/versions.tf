##
# Terraform & Provider Version Constraints
# Defines required Terraform version and AWS provider constraints for the
# bootstrap remote state storage S3 bucket module.
##

terraform {
  required_version = ">= 1.17.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

