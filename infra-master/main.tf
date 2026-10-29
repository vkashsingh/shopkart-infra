# Key pair for SSH access to the master machine
resource "aws_key_pair" "master" {
  key_name   = "shopkart-master"
  public_key = file(pathexpand(var.public_key_path))
}

# Security group allowing SSH, Jenkins, and SonarQube access strictly from authorized IP
resource "aws_security_group" "master" {
  name        = "shopkart-master-sg"
  description = "Security group for ShopKart DevOps master machine"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from authorized IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "Jenkins web UI from authorized IP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "SonarQube web UI from authorized IP"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "shopkart-master-sg"
  }
}

# EC2 instance hosting Jenkins, SonarQube, Docker, and DevOps tooling
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

