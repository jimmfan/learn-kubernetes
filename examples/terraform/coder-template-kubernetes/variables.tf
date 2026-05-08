variable "kubeconfig_path" {
  description = "Path to the kubeconfig used by the Kubernetes Terraform provider."
  type        = string
  default     = "~/.kube/config"
}

variable "workspace_image" {
  description = "Container image used for the Coder workspace pod."
  type        = string
  default     = "ubuntu:24.04"
}

