# Compute resources for the ShopKart master machine.
# Deploys the Ubuntu 24.04 EC2 instance running Jenkins, SonarQube, and CI/CD tools.

# EC2 instance: provisions the Ubuntu 24.04 master host running CI/CD tooling.
# Uses data.aws_ami, data.aws_subnets, aws_key_pair, aws_security_group, and aws_iam_instance_profile.
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
