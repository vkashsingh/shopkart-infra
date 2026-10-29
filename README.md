# shopkart-infra

Terraform for the ShopKart DevOps demo project.

## ShopKart project map

| Repo | What it holds | Changed by |
|---|---|---|
| [shopkart-app](https://github.com/vkashsingh/shopkart-app) | App code (React, Node.js), Dockerfiles, docker compose, Jenkinsfile | Developers |
| [shopkart-infra](https://github.com/vkashsingh/shopkart-infra) | Terraform: Jenkins master EC2, EKS cluster | DevOps |
| [shopkart-gitops](https://github.com/vkashsingh/shopkart-gitops) | Kubernetes YAML + Argo CD Application (what runs in EKS) | Jenkins (image tag), Argo CD (sync) |

**Flow:** push to shopkart-app → Jenkins (tests, SonarQube, OWASP, Trivy, build, push to Docker Hub) → Jenkins updates the image tag in shopkart-gitops → Argo CD syncs to EKS → Prometheus/Grafana monitor.

**You are here: shopkart-infra**

## Folders

| Folder | Creates | Run from |
|---|---|---|
| `infra-master/` | Ubuntu EC2 with Jenkins, SonarQube, Docker, Terraform, kubectl, Trivy | your laptop |
| `infra-eks/` | VPC + EKS cluster (Stage 4) | the master EC2 |

Region: `ap-southeast-2`. Destroy order: `infra-eks` first, then `infra-master`.
