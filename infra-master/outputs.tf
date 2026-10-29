output "public_ip" {
  description = "Public IP address of the master EC2 instance"
  value       = aws_instance.master.public_ip
}

output "ssh_command" {
  description = "Command to connect to the master EC2 instance via SSH"
  value       = "ssh -i ~/.ssh/shopkart-master ubuntu@${aws_instance.master.public_ip}"
}

output "jenkins_url" {
  description = "Web URL for Jenkins"
  value       = "http://${aws_instance.master.public_ip}:8080"
}

output "sonarqube_url" {
  description = "Web URL for SonarQube"
  value       = "http://${aws_instance.master.public_ip}:9000"
}

