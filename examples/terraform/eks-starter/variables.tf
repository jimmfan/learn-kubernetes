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

variable "tags" {
  description = "Tags applied to AWS resources."
  type        = map(string)
  default = {
    project = "learn-kubernetes"
    purpose = "eks-coder-learning"
    owner   = "james"
  }
}

