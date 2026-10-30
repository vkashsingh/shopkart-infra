# Terraform core and provider version requirements.
# Pins the minimum required Terraform version and AWS provider for infra-master.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
