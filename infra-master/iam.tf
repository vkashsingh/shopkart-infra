##
# IAM Roles & Instance Profiles
# Defines the IAM role, policy attachments, and instance profile granting the
# master EC2 host administrative permissions to provision downstream infrastructure.
##

# IAM role: defines the service role assumed by the master EC2 instance via STS.
# Bound to aws_iam_instance_profile.master and referenced by policy attachments.
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

# IAM policy attachment: attaches AWS-managed AdministratorAccess to the master IAM role.
# Enables CI/CD pipelines and Terraform on the master machine to manage EKS and AWS resources.
resource "aws_iam_role_policy_attachment" "master_admin" {
  role       = aws_iam_role.master.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Instance profile: wraps the IAM role so EC2 can assume it via instance metadata.
# Assigned directly to aws_instance.master via iam_instance_profile.
resource "aws_iam_instance_profile" "master" {
  name = "shopkart-master-instance-profile"
  role = aws_iam_role.master.name
}
