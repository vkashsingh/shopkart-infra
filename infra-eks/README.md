# ShopKart EKS Infrastructure (`infra-eks`)

This directory provisions the production-ready Amazon EKS cluster and dedicated VPC for the ShopKart application using official, battle-tested AWS Terraform modules.

---

## Architecture Overview

- **VPC (`shopkart-vpc`)**:
  - CIDR: `10.20.0.0/16` across 2 Availability Zones in `ap-southeast-2` (Sydney).
  - 2 Public Subnets (`10.20.1.0/24`, `10.20.2.0/24`) with tag `"kubernetes.io/role/elb" = "1"`.
  - 2 Private Subnets (`10.20.10.0/24`, `10.20.11.0/24`) with tag `"kubernetes.io/role/internal-elb" = "1"`.
  - Single NAT Gateway enabled for lab cost optimization (production should use 1 NAT GW per AZ).
- **EKS Cluster (`shopkart-eks`)**:
  - Kubernetes Version: `1.36` (configurable via `var.kubernetes_version`).
  - Private subnets for control plane ENIs and worker nodes.
  - Endpoint Access: Private access enabled; public access enabled and strictly restricted to `var.admin_cidrs`.
  - Authentication: `API` authentication mode with cluster creator admin permissions enabled, plus access entry for `var.extra_admin_arn` (e.g. Jenkins master role) mapped to `AmazonEKSClusterAdminPolicy`.
  - IRSA (IAM Roles for Service Accounts) enabled.
- **EKS Managed Node Group (`default`)**:
  - Instance Type: `m7i-flex.large` (2 vCPU, 8 GiB RAM).
  - AMI: `AL2023_x86_64_STANDARD` (Amazon Linux 2023).
  - Scaling: Desired 2, Min 1, Max 3.
  - Storage: 20 GB `gp3` encrypted root volume.
- **EKS Add-ons (most recent)**:
  - `vpc-cni`
  - `coredns`
  - `kube-proxy`
  - `aws-ebs-csi-driver` (integrated with an IRSA role attached to `AmazonEBSCSIDriverPolicy`).
- **StorageClass**:
  - Custom `gp3` StorageClass with `WaitForFirstConsumer` and `reclaimPolicy: Delete`, designated as default.

---

## Resource Map

| Resource Address | Purpose | Depends On |
|---|---|---|
| `data.aws_availability_zones.available` | Queries available Availability Zones in the current AWS region | AWS Provider |
| `module.vpc` | Provisions the dedicated VPC, subnets, NAT gateway, and ELB tags | `data.aws_availability_zones.available` |
| `module.ebs_csi_irsa` | Provisions IAM role for service accounts (IRSA) for the EBS CSI driver | `module.eks.oidc_provider_arn` |
| `module.eks` | Manages EKS control plane, managed node groups, access entries, and add-ons | `module.vpc.vpc_id`, `module.vpc.private_subnets`, `module.ebs_csi_irsa.arn`, `var.admin_cidrs`, `var.extra_admin_arn` |

---

## Apply Order

> [!IMPORTANT]
> Infrastructure must be provisioned in sequence. Do NOT apply `infra-eks` before `bootstrap` is created.

### Step 1: Provision the State S3 Bucket (`bootstrap/`)
Navigate to the `bootstrap/` directory and apply the local state configuration:
```bash
cd ../bootstrap
terraform init
terraform apply
```
Copy the resulting output:
```bash
terraform output bucket_name
# Output example: shopkart-tfstate-123456789012
```

### Step 2: Configure the Remote Backend
Open `infra-eks/versions.tf` and replace the placeholder bucket name with your bootstrap bucket:
```hcl
bucket = "shopkart-tfstate-<YOUR_ACCOUNT_ID>"
```

### Step 3: Configure Variables
Create your `terraform.tfvars` file from the example:
```bash
cp terraform.tfvars.example terraform.tfvars
```
Edit `terraform.tfvars` with:
- `admin_cidrs`: Your public IP or authorized CIDR block (e.g. `["203.0.113.50/32"]`).
- `extra_admin_arn`: The IAM role/user ARN for cluster administration (e.g., Jenkins master role ARN).

### Step 4: Apply `infra-eks`
```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

> [!NOTE]
> **Expected Wait Time**: Provisioning the VPC, EKS control plane, managed node group, and add-ons takes approximately **15 to 20 minutes**.

---

## Verification Commands

Once `terraform apply` finishes:

1. **Update kubeconfig**:
   ```bash
   aws eks update-kubeconfig --region ap-southeast-2 --name shopkart-eks
   ```

2. **Verify Nodes**:
   ```bash
   kubectl get nodes -o wide
   ```

3. **Verify All Pods & Add-ons**:
   ```bash
   kubectl get pods -A
   ```

4. **Verify StorageClasses**:
   ```bash
   kubectl get sc
   ```

### Default StorageClass Configuration (`gp2` -> `gp3`)

AWS EKS provisions a default `gp2` StorageClass. To make modern `gp3` the default storage class:

1. **Remove default annotation from `gp2`**:
   ```bash
   kubectl annotate storageclass gp2 storageclass.kubernetes.io/is-default-class-
   ```
   *(The trailing hyphen `-` removes the annotation).*

2. **Apply the `gp3` StorageClass**:
   ```bash
   kubectl apply -f k8s/storageclass-gp3.yaml
   ```

3. **Verify default status**:
   ```bash
   kubectl get sc
   # gp3 (default) should now have "(default)" next to its name
   ```

---

## Destroy Order

> [!WARNING]
> Running `terraform destroy` without first cleaning up Kubernetes-managed AWS resources (Load Balancers and EBS Volumes) will cause Terraform to fail or hang indefinitely while deleting VPC subnets, security groups, and internet gateways.

Always follow this exact teardown order:

1. **Delete all Kubernetes Services of type `LoadBalancer` and Ingresses**:
   ```bash
   kubectl delete svc --all-namespaces --selector=app.kubernetes.io/managed-by!=Helm # Or delete your Helm/ArgoCD releases
   ```
   Wait for AWS to fully release the Elastic Load Balancers (ALBs / NLBs) and detach their Network Interfaces (ENIs).

2. **Delete all PersistentVolumeClaims (PVCs)**:
   ```bash
   kubectl delete pvc --all-namespaces --all
   ```
   Ensure dynamic EBS volumes are deleted so they do not block security group deletion or incur orphaned storage charges.

3. **Destroy the EKS Infrastructure**:
   ```bash
   terraform destroy
   ```

4. **(Optional) Destroy Bootstrap S3 Bucket**:
   If decommissioning the entire project:
   ```bash
   cd ../bootstrap
   # Ensure the S3 bucket is empty, or empty it via AWS CLI if needed
   terraform destroy
   ```

---

## Estimated Monthly Cost Table (`ap-southeast-2` Sydney)

| Resource | Specification | Pricing Model | Approx. Monthly Cost (USD) |
|---|---|---|---|
| **EKS Control Plane** | 1 Cluster (`shopkart-eks`) | \$0.10 / hour | \$73.00 |
| **EC2 Worker Nodes** | 2x `m7i-flex.large` (2 vCPU, 8 GiB RAM) | ~\$0.1075 / hour each | \$154.80 |
| **EBS Node Root Volumes** | 2x 20 GB `gp3` | \$0.096 / GB-month | \$3.84 |
| **NAT Gateway** | 1 Single NAT Gateway (Lab) | \$0.059 / hour + data transfer | ~\$42.50 |
| **S3 Remote State** | State files + versioning | Storage + standard API calls | < \$0.10 |
| **Total Baseline** | **Standard 2-node lab cluster** | **~ \$9.15 / day** | **~ \$274.24 / month** |

> [!TIP]
> **Lab Cost Savings**: A single NAT Gateway is used across both Availability Zones to save ~\$42.50/month in lab environments. For high-availability production deployments, configure `single_nat_gateway = false` to run one NAT Gateway per AZ.
