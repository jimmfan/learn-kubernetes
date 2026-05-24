terraform {
  required_version = ">= 1.5.0"

  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
}

provider "coder" {}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "main" {
  arch = "amd64"
  os   = "linux"

  startup_script = <<-EOT
    set -e
    echo "Coder workspace ready for ${data.coder_workspace_owner.me.name}"
  EOT
}

resource "kubernetes_namespace" "workspace" {
  metadata {
    name = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"

    labels = {
      "app.kubernetes.io/managed-by" = "coder"
      "coder.com/owner"              = data.coder_workspace_owner.me.name
      "coder.com/workspace"          = data.coder_workspace.me.name
    }
  }
}

resource "kubernetes_deployment" "workspace" {
  metadata {
    name      = "workspace"
    namespace = kubernetes_namespace.workspace.metadata[0].name
  }

  spec {
    replicas = data.coder_workspace.me.start_count

    selector {
      match_labels = {
        app = "coder-workspace"
      }
    }

    template {
      metadata {
        labels = {
          app = "coder-workspace"
        }
      }

      spec {
        container {
          name    = "dev"
          image   = var.workspace_image
          command = ["sh", "-c", coder_agent.main.init_script]

          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.main.token
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }

            limits = {
              cpu    = "1000m"
              memory = "2Gi"
            }
          }
        }
      }
    }
  }
}
