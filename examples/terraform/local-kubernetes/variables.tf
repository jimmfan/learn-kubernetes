variable "kubeconfig_path" {
  description = "Path to the kubeconfig used to reach the local Docker Desktop cluster."
  type        = string
  default     = "~/.kube/config"
}

variable "namespace" {
  description = "Namespace for the local Terraform-managed app."
  type        = string
  default     = "tf-hello"
}

variable "replicas" {
  description = "Number of nginx replicas to run."
  type        = number
  default     = 2
}

