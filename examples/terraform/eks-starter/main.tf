# This starter is intentionally small: read it first, then decide whether to
# build the VPC/EKS resources directly or use the community EKS module.

locals {
  cluster_name = var.cluster_name
}

data "aws_availability_zones" "available" {
  state = "available"
}

output "next_steps" {
  value = [
    "Design VPC CIDR and subnet layout.",
    "Add an EKS cluster resource or the terraform-aws-modules/eks/aws module.",
    "Enable EKS Auto Mode or define managed node groups.",
    "Add IAM roles for cluster access and Pod Identity.",
    "Add outputs for kubeconfig generation and Coder Helm deployment.",
  ]
}

output "candidate_availability_zones" {
  value = slice(data.aws_availability_zones.available.names, 0, 3)
}

output "cluster_name" {
  value = local.cluster_name
}

