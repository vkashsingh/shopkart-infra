##
# Data Sources
# Discovers AWS caller account identity to generate globally unique,
# deterministic S3 bucket naming.
##

# Caller identity data source: queries the current AWS account ID and ARN.
# Supplies the AWS account ID used to construct the S3 bucket name in aws_s3_bucket.terraform_state.
data "aws_caller_identity" "current" {}

