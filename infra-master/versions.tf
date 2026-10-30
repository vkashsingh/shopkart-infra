##
# Terraform & Provider Version Constraints
# Defines the required Terraform core engine version and AWS provider plugin
# requirements for provisioning the ShopKart master machine infrastructure.
##

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

