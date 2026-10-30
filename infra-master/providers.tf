##
# AWS Provider Configuration
# Configures the AWS provider instance, target deployment region, and global
# default resource tags applied to all master infrastructure resources.
##

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      project = "shopkart"
    }
  }
}
