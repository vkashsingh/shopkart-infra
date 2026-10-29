##
# Network Infrastructure (VPC & Subnets)
# Provisions the dedicated ShopKart VPC with multi-AZ public and private subnets,
# a shared NAT gateway, and mandatory Kubernetes ELB discovery tags.
##

# VPC module: creates a multi-AZ VPC with 2 public subnets, 2 private subnets, and internet/NAT routing.
# Connects data.aws_availability_zones to feed private subnets into module.eks and worker node groups.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "shopkart-vpc"
  cidr = "10.20.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = ["10.20.1.0/24", "10.20.2.0/24"]
  private_subnets = ["10.20.10.0/24", "10.20.11.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Cost saving for lab, prod uses one per AZ

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

