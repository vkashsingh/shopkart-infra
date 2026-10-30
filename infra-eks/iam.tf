##
# IAM for EKS Pod Identity
# The EBS CSI driver needs AWS permissions to create and attach EBS volumes for PVCs.
# Pod Identity is used instead of IRSA because this account's SCP blocks creating
# IAM OIDC providers. Pod Identity needs no OIDC provider.
##

# IAM role assumed by the EBS CSI controller pod through EKS Pod Identity.
# Trusted by pods.eks.amazonaws.com; linked to the pod via the add-on's pod_identity_association in compute.tf.
resource "aws_iam_role" "ebs_csi" {
  name = "shopkart-ebs-csi-pod-identity"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

# AWS-managed policy with the EC2 permissions the EBS CSI driver needs (create, attach, delete volumes).
resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
