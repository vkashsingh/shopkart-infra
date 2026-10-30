##
# Data Sources
# Queries existing AWS infrastructure (default VPC and subnets) and dynamic
# AMI catalogs to discover the latest Ubuntu 24.04 LTS official image.
##

# Default VPC: looks up the AWS default VPC in the selected region.
# Provides the network boundary and VPC ID for aws_security_group.master.
data "aws_vpc" "default" {
  default = true
}

# Default subnets: queries all subnet IDs belonging to the default VPC.
# Supplies the subnet ID passed to aws_instance.master to place the EC2 instance.
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Ubuntu 24.04 LTS AMI: queries Canonical's latest official Noble Numbat 64-bit AMI.
# Supplies the ami image ID passed to aws_instance.master.
data "aws_ami" "ubuntu_24_04" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
