##
# Network & Access Control Resources
# Provisions the EC2 SSH key pair and security group rules controlling inbound
# network traffic from the administrator's authorized IP address.
##

# Key pair: imports developer public SSH key into EC2 for secure SSH authentication.
# Referenced by aws_instance.master to allow remote shell access.
resource "aws_key_pair" "master" {
  key_name   = "shopkart-master"
  public_key = file(pathexpand(var.public_key_path))
}

# Security group: restricts ingress on SSH, Jenkins, and SonarQube ports to var.my_ip.
# Attached directly to aws_instance.master and bound to data.aws_vpc.default.
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

