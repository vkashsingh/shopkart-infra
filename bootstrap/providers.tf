##
# AWS Provider Configuration
# Configures the AWS provider instance, region, and project default tags
# applied to the bootstrap remote state resources.
##

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      project = "shopkart"
    }
  }
}
