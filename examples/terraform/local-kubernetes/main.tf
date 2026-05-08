resource "kubernetes_namespace" "hello" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_deployment" "hello" {
  metadata {
    name      = "hello-web"
    namespace = kubernetes_namespace.hello.metadata[0].name

    labels = {
      "app.kubernetes.io/name" = "hello-web"
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "hello-web"
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "hello-web"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:1.27-alpine"

          port {
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "25m"
              memory = "32Mi"
            }

            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "hello" {
  metadata {
    name      = "hello-web"
    namespace = kubernetes_namespace.hello.metadata[0].name
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = "hello-web"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

