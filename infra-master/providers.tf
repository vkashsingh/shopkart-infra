# AWS provider configuration for infra-master.
# Configures the target deployment region and default project tags for all resources.

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      project = "shopkart"
    }
  }
}
