#!/usr/bin/env bash
set -euxo pipefail

# Redirect all stdout and stderr to /var/log/user-data.log
exec > >(tee -a /var/log/user-data.log) 2>&1

echo "=========================================================="
echo "Starting ShopKart Master bootstrap at $(date -u)"
echo "=========================================================="

export DEBIAN_FRONTEND=noninteractive

# Update system and install essential tools
apt-get update -y
apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  apt-transport-https \
  software-properties-common \
  git \
  unzip \
  jq

# 1. OpenJDK 21
echo "Installing OpenJDK 21..."
apt-get install -y openjdk-21-jdk

# 2. Docker Engine from official Docker apt repository
echo "Installing Docker Engine..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

# 3. Jenkins LTS from official Jenkins apt repository
echo "Installing Jenkins LTS..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key | tee /etc/apt/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -y
apt-get install -y jenkins
systemctl enable jenkins

# Add users jenkins and ubuntu to docker group, then restart Jenkins
usermod -aG docker ubuntu || true
usermod -aG docker jenkins || true
systemctl restart jenkins

# 4. AWS CLI v2
echo "Installing AWS CLI v2..."
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update
rm -rf /tmp/aws /tmp/awscliv2.zip

# 5. Terraform from HashiCorp apt repository
echo "Installing Terraform..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
chmod a+r /etc/apt/keyrings/hashicorp.gpg
echo "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

apt-get update -y
apt-get install -y terraform

# 6. kubectl
echo "Installing kubectl..."
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

# 7. Helm
echo "Installing Helm..."
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor -o /etc/apt/keyrings/helm.gpg
chmod a+r /etc/apt/keyrings/helm.gpg
echo "deb [signed-by=/etc/apt/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | tee /etc/apt/sources.list.d/helm.list > /dev/null

apt-get update -y
apt-get install -y helm

# 8. Trivy from official apt repository
echo "Installing Trivy..."
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /etc/apt/keyrings/trivy.gpg
chmod a+r /etc/apt/keyrings/trivy.gpg
echo "deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/trivy.list > /dev/null

apt-get update -y
apt-get install -y trivy

# 9. yq
echo "Installing yq..."
curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o /usr/local/bin/yq
chmod +x /usr/local/bin/yq

# 10. SonarQube configuration & deployment
echo "Configuring SonarQube system requirements..."
cat << 'SYSCTL_EOF' > /etc/sysctl.d/99-sonarqube.conf
vm.max_map_count=524288
fs.file-max=131072
SYSCTL_EOF
sysctl -p /etc/sysctl.d/99-sonarqube.conf

cat << 'LIMITS_EOF' > /etc/security/limits.d/99-sonarqube.conf
sonarqube   nofile   131072
sonarqube   nproc    8192
LIMITS_EOF

echo "Setting up SonarQube docker compose..."
mkdir -p /opt/sonarqube

# Generate secure random DB password into /opt/sonarqube/.env (chmod 600)
POSTGRES_PASS=$(openssl rand -hex 16)
cat << ENV_EOF > /opt/sonarqube/.env
POSTGRES_USER=sonar
POSTGRES_PASSWORD=${POSTGRES_PASS}
POSTGRES_DB=sonarqube
ENV_EOF
chmod 600 /opt/sonarqube/.env

cat << 'COMPOSE_EOF' > /opt/sonarqube/docker-compose.yml
services:
  sonarqube:
    image: sonarqube:26.8.0.126808-community
    restart: unless-stopped
    ports:
      - "9000:9000"
    environment:
      - SONAR_JDBC_USERNAME=${POSTGRES_USER}
      - SONAR_JDBC_PASSWORD=${POSTGRES_PASSWORD}
      - SONAR_JDBC_URL=jdbc:postgresql://db:5432/${POSTGRES_DB}
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    depends_on:
      - db
    ulimits:
      nofile:
        soft: 131072
        hard: 131072

  db:
    image: postgres:17
    restart: unless-stopped
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - postgresql_data:/var/lib/postgresql/data

volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
  postgresql_data:
COMPOSE_EOF

# Launch SonarQube with docker compose
docker compose -f /opt/sonarqube/docker-compose.yml --env-file /opt/sonarqube/.env up -d

# Completion marker
touch /var/log/bootstrap-done
echo "=========================================================="
echo "ShopKart Master bootstrap completed at $(date -u)"
echo "=========================================================="

