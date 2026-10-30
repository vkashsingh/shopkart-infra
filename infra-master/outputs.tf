##
# Outputs
# Exposes connection strings, web application URLs, and public network endpoints
# for connecting to and interacting with the master CI/CD machine.
##

output "public_ip" {
  description = "Public IPv4 address of the master EC2 instance"
  value       = aws_instance.master.public_ip
}

output "ssh_command" {
  description = "Ready-to-use SSH connection command to access the master EC2 instance"
  value       = "ssh -i ~/.ssh/shopkart-master ubuntu@${aws_instance.master.public_ip}"
}

output "jenkins_url" {
  description = "HTTP URL to access the Jenkins web user interface on port 8080"
  value       = "http://${aws_instance.master.public_ip}:8080"
}

output "sonarqube_url" {
  description = "HTTP URL to access the SonarQube web user interface on port 9000"
  value       = "http://${aws_instance.master.public_ip}:9000"
}
