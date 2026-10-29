##
# Data Sources
# Queries available AWS Availability Zones in the active region to dynamically
# allocate subnets for the VPC and EKS node groups.
##

# Availability zones data source: queries active, accessible AZs in the current AWS region.
# Provides AZ names sliced to 2 zones for module.vpc.
data "aws_availability_zones" "available" {
  state = "available"
}

