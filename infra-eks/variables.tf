##
# Input Variables
# Declares configurable inputs for the EKS cluster, network CIDRs, Kubernetes version,
# and external administrator IAM identity mappings.
##

variable "region" {
  description = "AWS region for the EKS cluster and VPC infrastructure"
  type        = string
  default     = "ap-southeast-2"
}

variable "kubernetes_version" {
  description = "Kubernetes control plane and worker node version"
  type        = string
  default     = "1.37"
}

variable "admin_cidrs" {
  description = "List of IPv4 CIDR blocks permitted to access the EKS cluster public API server endpoint"
  type        = list(string)
}

variable "extra_admin_arn" {
  description = "IAM principal ARN granted AmazonEKSClusterAdminPolicy with cluster-wide scope"
  type        = string
}
