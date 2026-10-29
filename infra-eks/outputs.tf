##
# Outputs
# Exposes cluster identity metadata, AWS region, and pre-formatted CLI commands
# for authenticating kubectl to the EKS control plane.
##

output "cluster_name" {
  description = "Name of the provisioned Amazon EKS cluster"
  value       = module.eks.cluster_name
}

output "region" {
  description = "AWS region hosting the EKS cluster and supporting resources"
  value       = var.region
}

output "kubeconfig" {
  description = "AWS CLI command to configure kubectl credentials for the cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "kubeconfig_command" {
  description = "AWS CLI command to configure kubectl credentials for the cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
