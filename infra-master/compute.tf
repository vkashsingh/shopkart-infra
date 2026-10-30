##
# Compute Resources
# Deploys the master EC2 instance configured with IMDSv2, an encrypted gp3 root
# volume, and an automated user-data bootstrap script for CI/CD tooling.
##

# EC2 instance: deploys the master host running Jenkins, SonarQube, Docker, and CLIs.
# Connects data.aws_ami, data.aws_subnets, aws_key_pair, aws_iam_instance_profile, and aws_security_group.
resource "aws_instance" "master" {
  ami                  = data.aws_ami.ubuntu_24_04.id
  instance_type        = var.instance_type
  subnet_id            = tolist(data.aws_subnets.default.ids)[0]
  key_name             = aws_key_pair.master.key_name
  iam_instance_profile = aws_iam_instance_profile.master.name

  vpc_security_group_ids = [
    aws_security_group.master.id
  ]

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "shopkart-master-root-vol"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  user_data = file("${path.module}/scripts/user-data.sh")

  tags = {
    Name = "shopkart-master"
  }
}

