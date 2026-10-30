# ShopKart Infrastructure

Terraform infrastructure for the ShopKart project in AWS region `ap-southeast-2` (Sydney). It provisions a Jenkins and SonarQube master EC2 instance and a multi-AZ Amazon EKS cluster, with Terraform remote state stored in S3.

## Project Map

| Repo | What it holds | Changed by |
|---|---|---|
| [shopkart-app](https://github.com/vkashsingh/shopkart-app) | App source (React, Node.js), Dockerfiles, compose, Jenkinsfile | Developers |
| [shopkart-infra](https://github.com/vkashsingh/shopkart-infra) | Terraform: state bucket, Jenkins master EC2, VPC, EKS cluster | DevOps |
| [shopkart-gitops](https://github.com/vkashsingh/shopkart-gitops) | Plain Kubernetes YAML + Argo CD Application | Jenkins, Argo CD |

You are here: `shopkart-infra`

## Folders

| Folder | What it creates | Run from |
|---|---|---|
| `bootstrap/` | S3 remote state bucket with versioning and encryption | Laptop (local state) |
| `infra-master/` | Ubuntu 24.04 EC2 with Jenkins, SonarQube, Docker, and DevOps tooling | Laptop (local state) |
| `infra-eks/` | VPC (2 AZs) and EKS cluster with managed node group and add-ons | Master EC2 (S3 state) |

## infra-master

```mermaid
flowchart LR
    Role["IAM Role<br/>(AdministratorAccess)"] --> Profile["Instance Profile"] --> EC2["Master EC2<br/>(Jenkins, SonarQube, Docker, Trivy)"]
    KeyPair["Key Pair"] --> EC2
    SG["Security Group"] --> EC2
```

The master EC2 runs on Ubuntu 24.04 with an attached instance profile for AWS administration. Security group rules restrict SSH, Jenkins, and SonarQube access to your IP address.

## infra-eks

```mermaid
flowchart TD
    subgraph ControlPlane["Amazon EKS Control Plane"]
        API["API Server (Private + Public Admin)"]
    end
    subgraph VPC["ShopKart VPC (10.20.0.0/16)"]
        subgraph Zone1["Availability Zone 1"]
            Pub1["Public Subnet 1<br/>(NAT Gateway & Load Balancers)"]
            Priv1["Private Subnet 1<br/>(Worker Nodes)"]
        end
        subgraph Zone2["Availability Zone 2"]
            Pub2["Public Subnet 2<br/>(Load Balancers)"]
            Priv2["Private Subnet 2<br/>(Worker Nodes)"]
        end
    end
    API -.-> Priv1
    API -.-> Priv2
    Priv1 -.->|"outbound"| Pub1
    Priv2 -.->|"outbound"| Pub1
```

The VPC spans 2 Availability Zones with public subnets hosting the NAT gateway and load balancers, and private subnets hosting the managed worker nodes. The EKS control plane connects to the private subnets and exposes endpoints for internal communication and authorized administrative access.

## Apply Order

Apply `bootstrap/` first from your laptop, then `infra-master/` from your laptop, and finally `infra-eks/` from the master EC2.
