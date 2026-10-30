# IAM permissions for the master EC2 instance.
# Defines the IAM role, AdministratorAccess policy attachment, and instance profile.

# IAM role: defines the service role assumed by the master EC2 instance via STS.
# Wrapped by aws_iam_instance_profile.master and attached to AdministratorAccess.
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

# Policy attachment: attaches AWS-managed AdministratorAccess to the master role.
# Grants admin permissions to aws_iam_role.master to provision lab infrastructure.
resource "aws_iam_role_policy_attachment" "master_admin" {
  role       = aws_iam_role.master.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Instance profile: wraps the IAM role so EC2 can use it.
# Used by aws_instance.master to assume the role via instance metadata.
resource "aws_iam_instance_profile" "master" {
  name = "shopkart-master-instance-profile"
  role = aws_iam_role.master.name
}
