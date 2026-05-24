variable "region" {
  description = "AWS region for the learning cluster."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name for the EKS learning cluster."
  type        = string
  default     = "coder-learning"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.33"
}

variable "vpc_cidr" {
  description = "CIDR block for the learning VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "Use 2 or 3 availability zones for this lab."
  }
}

variable "node_instance_types" {
  description = "EC2 instance types for the default managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  description = "Minimum size for the default managed node group."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum size for the default managed node group."
  type        = number
  default     = 2
}

variable "node_desired_size" {
  description = "Desired size for the default managed node group."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags applied to AWS resources."
  type        = map(string)
  default = {
    project = "learn-kubernetes"
    purpose = "eks-coder-learning"
    owner   = "james"
  }
}
