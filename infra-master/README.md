# ShopKart DevOps Lab - Master Machine Infrastructure

This Terraform module provisions the dedicated "master" machine for the ShopKart DevOps lab in AWS region `ap-southeast-2` (Sydney). The instance hosts Jenkins, SonarQube, Docker, and standard deployment CLI tooling.

## State Management

Local state (`terraform.tfstate`) is acceptable here because this is a single-developer, ephemeral lab environment with no concurrent execution risk or loss of shared team state. In production, a remote backend such as AWS S3 with DynamoDB state locking (or Terraform Cloud) is essential for team collaboration, encryption at rest, state versioning, and atomic lock protection.

## Resource Summary

- `aws_key_pair.master`: Imports the developer's public SSH key into AWS EC2 for secure SSH authentication.
- `aws_security_group.master`: Restricts ingress on ports 22 (SSH), 8080 (Jenkins), and 9000 (SonarQube) strictly to `var.my_ip`, while allowing full outbound egress.
- `aws_iam_role.master`: Creates an IAM service role assumed by the master EC2 instance.
- `aws_iam_role_policy_attachment.master_admin`: Attaches `AdministratorAccess` so Terraform on the master machine can provision EKS and lab infrastructure.
- `aws_iam_instance_profile.master`: Exposes the IAM role credentials to the EC2 instance metadata service.
- `aws_instance.master`: Deploys the encrypted Ubuntu 24.04 LTS `t3.large` instance with IMDSv2 and user_data bootstrap script.

## Prerequisites

1. Generate the SSH key pair locally if you have not already:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/shopkart-master -C "shopkart-master"
   ```
2. Determine your public IPv4 address:
   ```bash
   curl -s https://checkip.amazonaws.com
   ```
3. Copy and configure variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars and set my_ip = "<YOUR_IP>/32"
   ```

## Apply Steps

1. **Format and initialize Terraform**:
   ```bash
   cd infra-master
   terraform fmt
   terraform init
   terraform validate
   ```

2. **Review the execution plan**:
   ```bash
   terraform plan
   ```

3. **Provision the infrastructure**:
   ```bash
   terraform apply
   ```

## Verify Steps

1. **Check outputs**:
   Terraform will display `public_ip`, `ssh_command`, `jenkins_url`, and `sonarqube_url`.

2. **Connect via SSH**:
   ```bash
   ssh -i ~/.ssh/shopkart-master ubuntu@<PUBLIC_IP>
   ```

3. **Monitor bootstrap status**:
   ```bash
   # Follow bootstrap logs
   tail -f /var/log/user-data.log

   # Verify bootstrap completion marker
   ls -la /var/log/bootstrap-done
   ```

4. **Verify installed tooling**:
   ```bash
   java -version
   jenkins --version
   docker --version
   aws --version
   terraform version
   kubectl version --client
   helm version
   trivy --version
   yq --version
   ```

5. **Verify SonarQube container**:
   ```bash
   docker ps
   # SonarQube should be running on port 9000
   ```

6. **Access web interfaces in browser**:
   - Jenkins: `http://<PUBLIC_IP>:8080` (Retrieve initial admin password via `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`)
   - SonarQube: `http://<PUBLIC_IP>:9000` (Default credentials: `admin` / `admin`)

## Destroy Steps

To tear down all provisioned resources and prevent ongoing AWS charges:

```bash
cd infra-master
terraform destroy
```

