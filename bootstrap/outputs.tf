##
# Outputs
# Exposes the created S3 state bucket identifier for consumption in downstream
# backend configuration files (such as infra-eks/versions.tf).
##

output "bucket_name" {
  description = "The name of the S3 bucket created for Terraform remote state"
  value       = aws_s3_bucket.terraform_state.id
}
