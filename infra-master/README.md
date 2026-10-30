# ShopKart DevOps Lab - Master Machine Infrastructure

This Terraform module provisions the dedicated "master" machine for the ShopKart DevOps lab in AWS region `ap-southeast-2` (Sydney). The instance hosts Jenkins, SonarQube, Docker, and standard deployment CLI tooling.

## State Management

Local state (`terraform.tfstate`) is acceptable here because this is a single-developer, ephemeral lab environment with no concurrent execution risk or loss of shared team state. In production, a remote backend such as AWS S3 with DynamoDB state locking (or Terraform Cloud) is essential for team collaboration, encryption at rest, state versioning, and atomic lock protection.

## Resource Map

| Resource Address | Purpose | Depends On |
|---|---|---|
| `data.aws_vpc.default` | Discovers the default AWS VPC in the target region | AWS Provider |
| `data.aws_subnets.default` | Queries subnets in the default VPC to select host placement | `data.aws_vpc.default` |
| `data.aws_ami.ubuntu_24_04` | Discovers the latest official Ubuntu 24.04 LTS Noble 64-bit AMI | AWS Provider |
| `aws_key_pair.master` | Imports the developer SSH public key into EC2 | `var.public_key_path` |
| `aws_security_group.master` | Restricts ingress on ports 22, 8080, and 9000 strictly to `var.my_ip` | `data.aws_vpc.default`, `var.my_ip` |
| `aws_iam_role.master` | Creates IAM service role assumed by the EC2 instance | AWS Provider |
| `aws_iam_role_policy_attachment.master_admin` | Attaches `AdministratorAccess` policy to the master IAM role | `aws_iam_role.master` |
| `aws_iam_instance_profile.master` | Wraps IAM role so EC2 can retrieve temporary STS credentials | `aws_iam_role.master` |
| `aws_instance.master` | Provisions the Ubuntu 24.04 EC2 host with encrypted gp3 and user_data | `data.aws_ami.ubuntu_24_04`, `data.aws_subnets.default`, `aws_key_pair.master`, `aws_security_group.master`, `aws_iam_instance_profile.master` |

## Bootstrap Script Steps (`scripts/user-data.sh`)

When `aws_instance.master` boots up, `scripts/user-data.sh` automatically installs and configures all lab prerequisites:

1. **System update & base utilities**: Updates apt repositories and installs base network and packaging tools (`curl`, `git`, `jq`, `unzip`, `software-properties-common`).
2. **OpenJDK 21**: Installs Java 21 JDK required to run Jenkins and execute SonarQube analysis scanners.
3. **Docker Engine**: Installs official Docker CE, containerd, and docker-compose plugin from Docker's apt repo, then starts the service.
4. **Jenkins LTS**: Adds the official Jenkins Debian repository, installs the latest LTS release, and starts the Jenkins daemon.
5. **Docker user permissions**: Adds `ubuntu` and `jenkins` users to the `docker` group and restarts Jenkins so CI/CD jobs can build containers without sudo.
6. **AWS CLI v2**: Unpacks and runs the official AWS CLI v2 Linux installer to enable scripted interactions with AWS services.
7. **Terraform**: Adds the official HashiCorp apt repository and installs the Terraform CLI for managing downstream infrastructure.
8. **kubectl**: Fetches the latest stable Kubernetes CLI binary and places it in `/usr/local/bin` with execution permissions.
9. **Helm 3**: Configures the official Helm repository and installs the Helm package manager for Kubernetes deployments.
10. **Trivy**: Configures Aqua Security's apt repository and installs Trivy for container image and filesystem vulnerability scanning.
11. **yq**: Downloads the static `yq` binary to `/usr/local/bin` for automated YAML manifest processing in CI/CD pipelines.
12. **SonarQube host tuning**: Configures `vm.max_map_count=524288` and `fs.file-max=131072` in `/etc/sysctl.d/`, and file/process limits in `/etc/security/limits.d/`.
13. **SonarQube & PostgreSQL containerization**: Generates a random database password into `/opt/sonarqube/.env` and launches SonarQube Community + PostgreSQL 17 using Docker Compose.
14. **Completion marker**: Creates `/var/log/bootstrap-done` to signal that all packages and services are initialized.

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
