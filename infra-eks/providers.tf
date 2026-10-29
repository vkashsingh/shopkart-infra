##
# AWS Provider Configuration
# Configures the AWS provider instance, operational region, and default tags
# automatically applied to all provisioned EKS and VPC resources.
##

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      project = "shopkart"
    }
  }
}
