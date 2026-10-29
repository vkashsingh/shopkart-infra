# Bootstrap: Terraform Remote State Storage

This directory manages the initial S3 bucket used to store Terraform remote state for the ShopKart infrastructure (such as `infra-eks/`). It uses local state to avoid circular dependencies.

## Resource Map

| Resource Address | Purpose | Depends On |
|---|---|---|
| `data.aws_caller_identity.current` | Discovers current AWS account ID for deterministic bucket naming | AWS Provider |
| `aws_s3_bucket.terraform_state` | Creates S3 bucket `shopkart-tfstate-<account_id>` | `data.aws_caller_identity.current` |
| `aws_s3_bucket_versioning.terraform_state` | Enables object versioning to protect state history | `aws_s3_bucket.terraform_state` |
| `aws_s3_bucket_server_side_encryption_configuration.terraform_state` | Enforces SSE-S3 AES-256 encryption at rest | `aws_s3_bucket.terraform_state` |
| `aws_s3_bucket_public_access_block.terraform_state` | Blocks all public access, ACLs, and bucket policies | `aws_s3_bucket.terraform_state` |

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the plan:
   ```bash
   terraform plan
   ```

3. Apply to create the S3 bucket:
   ```bash
   terraform apply
   ```

4. Note the output bucket name:
   ```bash
   terraform output bucket_name
   ```
   Copy this bucket name into `../infra-eks/versions.tf`.
