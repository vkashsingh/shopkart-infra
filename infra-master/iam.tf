# IAM role for the master EC2 instance
resource "aws_iam_role" "master" {
  name = "shopkart-master-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "shopkart-master-role"
  }
}

# Attach AdministratorAccess policy so that Terraform running on the master machine can provision EKS and associated resources.
# NOTE: In production environments, never attach AdministratorAccess. Production requires a least-privilege
# scoped IAM policy restricting permissions to the specific resources and actions needed by the CI/CD pipeline.
resource "aws_iam_role_policy_attachment" "master_admin" {
  role       = aws_iam_role.master.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Instance profile exposing the IAM role to the EC2 instance
resource "aws_iam_instance_profile" "master" {
  name = "shopkart-master-instance-profile"
  role = aws_iam_role.master.name
}

