output "namespace" {
  value = kubernetes_namespace.hello.metadata[0].name
}

output "service_name" {
  value = kubernetes_service.hello.metadata[0].name
}

output "port_forward_command" {
  value = "kubectl port-forward -n ${var.namespace} svc/hello-web 8080:80"
}

