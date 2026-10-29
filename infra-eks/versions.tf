##
# Terraform & Backend Configuration
# Specifies the required Terraform version, HashiCorp AWS provider constraints,
# and the S3 remote backend configuration with native S3 state locking.
##

terraform {
  required_version = ">= 1.17.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    # Replace placeholder with the bucket name output from bootstrap/ (e.g. shopkart-tfstate-<account_id>)
    # bucket passed at init: terraform init -backend-config="bucket=shopkart-tfstate-<account_id>"
    key          = "infra-eks/terraform.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
    encrypt      = true
  }
}

