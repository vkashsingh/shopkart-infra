# Data sources for infra-master.
# Discovers the default VPC, default subnets, and latest Ubuntu 24.04 LTS AMI.

# Default VPC: looks up the AWS default VPC in the region.
# Used by aws_security_group.master to associate the security group with the VPC.
data "aws_vpc" "default" {
  default = true
}

# Default subnets: queries all subnet IDs belonging to the default VPC.
# Used by aws_instance.master to place the EC2 instance in a default subnet.
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Ubuntu 24.04 LTS AMI: finds the latest official Noble Numbat 64-bit AMI.
# Used by aws_instance.master as the machine image for the master host.
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
