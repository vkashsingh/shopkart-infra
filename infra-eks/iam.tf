##
# IAM Roles & Service Account Policies (IRSA)
# Provisions the IAM Role for Service Accounts (IRSA) allowing the AWS EBS CSI
# driver controller pod to dynamically provision and manage EBS persistent volumes.
##

# EBS CSI IRSA role: creates an IAM role assumed via OIDC web identity by the ebs-csi-controller service account.
# Attaches AmazonEBSCSIDriverPolicy and binds to module.eks.oidc_provider_arn for the aws-ebs-csi-driver addon.
module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"

  name = "shopkart-ebs-csi"

  policies = {
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}
