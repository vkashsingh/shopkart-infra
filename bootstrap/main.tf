##
# Storage Infrastructure (State S3 Bucket)
# Provisions an encrypted, versioned, and strictly private S3 bucket to serve
# as the centralized remote state store for downstream Terraform modules.
##

# S3 bucket: provides remote storage for Terraform state files across environments.
# Links to data.aws_caller_identity.current for naming and is protected by force_destroy = false.
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "shopkart-tfstate-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

# S3 bucket versioning: maintains full revision history of Terraform state objects.
# Attached directly to aws_s3_bucket.terraform_state to protect against state corruption.
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 server-side encryption: enforces default SSE-S3 AES-256 encryption at rest.
# Attached directly to aws_s3_bucket.terraform_state to secure stored state data.
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 public access block: restricts all public access, ACLs, and policies bucket-wide.
# Attached directly to aws_s3_bucket.terraform_state to guarantee complete privacy.
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
