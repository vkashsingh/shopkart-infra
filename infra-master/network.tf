# Network and access control resources for the master instance.
# Manages the EC2 SSH key pair and security group rules for Jenkins and SonarQube.

# Key pair: imports developer public SSH key into AWS EC2.
# Used by aws_instance.master to authenticate SSH login sessions.
resource "aws_key_pair" "master" {
  key_name   = "shopkart-master"
  public_key = file(pathexpand(var.public_key_path))
}

# Security group: firewall restricting SSH, Jenkins, and SonarQube ingress to var.my_ip.
# Placed in data.aws_vpc.default and attached to aws_instance.master.
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
