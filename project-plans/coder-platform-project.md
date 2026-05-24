# Coder Platform Project Plan

Goal: become useful on the Coder workstream now, while learning platform concepts that transfer to ARC later.

## Phase 1: Understand Coder Locally

1. Install Coder locally with Docker.
2. Create a basic admin user.
3. Create one simple Docker-based workspace template.
4. Add Python, git, and common CLI tools to the workspace image.
5. Test the full lifecycle:
   - create workspace
   - start workspace
   - connect through browser or SSH
   - stop workspace
   - delete workspace

Primary learning: what Coder actually does for developers.

## Phase 2: Build A Useful Python Workspace

1. Create a reusable Python dev template.
2. Add template parameters:
   - Python version
   - repo URL
   - workspace size
   - auto-stop timeout
3. Add startup scripts:
   - clone repo
   - install dependencies
   - run `python --version`
   - optionally create a virtual environment
4. Expose a sample app port.
5. Document how a developer would use it.

Primary learning: Coder templates as a product surface.

## Phase 3: Coder On One EC2 Instance

1. Use Terraform to create a small EC2 host.
2. Install Docker and Coder via user data.
3. Store Coder data on EBS.
4. Access it through a safe method:
   - Tailscale
   - Cloudflare Tunnel
   - SSM port forwarding
   - HTTPS later
5. Add auto-stop guidance for workspaces.
6. Add destroy/recreate workflow.

Primary learning: self-hosting Coder cheaply.

## Phase 4: Coder On Kubernetes

1. Create a local Kubernetes cluster with Docker Desktop (if `kind` or `k3d` does not work) 
2. Install Coder with Helm.
3. Configure workspace pods.
4. Add persistent volumes.
5. Create a Kubernetes-backed Python workspace template.
6. Add local observability with Prometheus and Grafana:
   - install `kube-prometheus-stack`
   - view Kubernetes pod, node, and PVC dashboards
   - create a small Coder workspace health dashboard
   - track CPU, memory, pod restarts, storage usage, and workspace pod status
   - keep this local-first so the lab costs `$0`
7. Practice debugging:
   - pods
   - services
   - PVCs
   - logs
   - events
   - service accounts

Primary learning: how Coder maps developer workspaces onto Kubernetes, and how observability helps explain what the platform is doing.

## Phase 5: Coder On EKS

1. Use a small EKS cluster only when needed.
2. Install Coder with Helm.
3. Add ingress/load balancer.
4. Add persistent storage with EBS CSI.
5. Add reasonable resource limits.
6. Test one realistic workspace.
7. Add an optional observability comparison:
   - start with self-hosted Prometheus and Grafana in-cluster
   - optionally compare Grafana Cloud free tier
   - optionally compare Amazon Managed Service for Prometheus and Amazon Managed Grafana
   - avoid managed observability until the local setup is understood
8. Destroy the cluster after labs.

Primary learning: production-shaped Coder architecture, plus the cost and operational tradeoffs of self-hosted versus managed observability.

## Observability Cost Guidance

For an individual project, observability is worth adding if it stays intentionally small.

Recommended path:

1. Use local Prometheus and Grafana first.
2. Add `kube-prometheus-stack` during the local Kubernetes phase.
3. Use dashboards to answer practical platform questions:
   - Are Coder and workspace pods healthy?
   - Are workspaces using too much CPU or memory?
   - Are pods restarting?
   - Are PVCs filling up?
   - Is the cluster running out of capacity?
4. Treat Grafana Cloud free tier as a later experiment.
5. Treat AWS managed Prometheus and Grafana as an EKS comparison lab, not the default path.

Cost posture:

- local Prometheus and Grafana: `$0`
- Grafana Cloud free tier: `$0` within limits
- Amazon Managed Grafana: useful AWS practice, but usually not needed early
- Amazon Managed Service for Prometheus: powerful, but sample ingestion can become a real cost driver

## Terraform Implementation Notes

Coder uses Terraform in two different ways in this project:

1. Platform Terraform creates the place where Coder runs.
   - `part-02-coder-platform/terraform/coder-ec2` creates AWS resources such as EC2, EBS, security groups, IAM roles, and maybe DNS later.
   - `part-02-coder-platform/terraform/coder-eks` creates AWS resources such as EKS, node groups, add-ons, load balancers, IAM roles, and storage classes.
2. Coder template Terraform creates each developer workspace.
   - A Coder template is Terraform code that Coder runs when a user creates, starts, stops, or deletes a workspace.
   - The template can create Docker containers, Kubernetes pods, persistent volumes, cloud VMs, or other workspace resources.
   - The `coder/coder` provider describes the Coder-specific pieces, such as agents, apps, metadata, and user-facing parameters.
   - Another provider describes the actual compute target, such as Docker for local workspaces or Kubernetes for pod-based workspaces.

The important distinction: Terraform for the platform answers "where does Coder live?", while Terraform inside a Coder template answers "what gets created for one developer workspace?"

## Example Coder Template Shape

Start with a Docker-backed template because it is cheaper and easier to understand than Kubernetes. This belongs in a future path such as `part-02-coder-platform/coder-templates/python-docker/main.tf`.

The template should have two files at first:

- `part-02-coder-platform/coder-templates/python-docker/main.tf`
- `part-02-coder-platform/coder-templates/python-docker/build/Dockerfile`

Example `build/Dockerfile`:

```dockerfile
FROM python:3.12-bookworm

# Coder's agent bootstrap needs curl. The template startup script needs git.
# sudo is useful while learning, but a stricter production image would avoid it
# or give it only where needed.
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl git sudo \
  && rm -rf /var/lib/apt/lists/*

# Create the same non-root user that many Coder examples use.
# This makes the workspace feel like a normal developer machine instead of root.
ARG USER=coder
RUN useradd --groups sudo --create-home --shell /bin/bash ${USER} \
  && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} \
  && chmod 0440 /etc/sudoers.d/${USER}

USER ${USER}
WORKDIR /home/${USER}
```

Example `main.tf`:

```hcl
terraform {
  required_providers {
    # The Coder provider exposes Coder-specific resources such as agents,
    # apps, parameters, metadata, and workspace lifecycle information.
    coder = {
      source = "coder/coder"
    }

    # The Docker provider is the first compute target for local learning.
    # Later, replace this with the Kubernetes provider for workspace pods.
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

locals {
  # Keep the username in one place so paths, image build args, and app URLs
  # stay consistent as the template grows.
  username = data.coder_workspace_owner.me.name
}

provider "coder" {}
provider "docker" {}

# The provisioner is the worker process that runs this Terraform.
# Reading its arch/os lets the agent match the machine doing the provisioning.
data "coder_provisioner" "me" {}

# Coder injects workspace context when it runs this Terraform.
# This tells the template whether the workspace is being started or stopped.
data "coder_workspace" "me" {}

# This gives access to the user who owns the workspace.
# Useful for naming resources and cloning user-specific dotfiles later.
data "coder_workspace_owner" "me" {}

# A parameter becomes a form field in the Coder UI.
# This is how a platform team turns Terraform into a developer-facing product.
data "coder_parameter" "repo_url" {
  name         = "repo_url"
  display_name = "Repository URL"
  description  = "Git repository to clone when the workspace starts."
  type         = "string"
  default      = "https://github.com/example/python-app.git"
  mutable      = true
}

# The agent is the process that runs inside the workspace and connects back to Coder.
# Without an agent, Coder can create infrastructure but cannot give the developer
# a terminal, editor connection, startup logs, or workspace health.
resource "coder_agent" "dev" {
  os   = "linux"
  arch = data.coder_provisioner.me.arch

  # This script runs when the workspace starts.
  # Keep early scripts simple: install tools, clone a repo, print versions,
  # and leave obvious logs for troubleshooting.
  startup_script = <<-EOT
    set -e

    echo "Workspace owner: ${data.coder_workspace_owner.me.name}"
    echo "Repo URL: ${data.coder_parameter.repo_url.value}"

    if [ ! -d "$HOME/project/.git" ]; then
      git clone "${data.coder_parameter.repo_url.value}" "$HOME/project"
    fi

    cd "$HOME/project"
    python --version || true
  EOT

  # These environment variables make git commits work naturally in the workspace.
  # Coder gets the values from the user who owns the workspace.
  env = {
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL    = data.coder_workspace_owner.me.email
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email
  }

  # Resource monitoring gives Coder workspace-level signals for common
  # developer problems like running out of memory or disk.
  resources_monitoring {
    memory {
      enabled   = true
      threshold = 80
    }

    volume {
      enabled   = true
      path      = "/home/coder"
      threshold = 80
    }
  }
}

# Build the workspace image from the Dockerfile beside this template.
# In a team setup, you would usually build and publish this image through CI
# instead of building it during every template update.
resource "docker_image" "workspace" {
  name = "coder-python-workspace:${data.coder_workspace.me.id}"

  build {
    context = "./build"
    build_args = {
      USER = local.username
    }
  }

  # Rebuild the image when the Dockerfile changes.
  triggers = {
    dockerfile_sha1 = filesha1("${path.module}/build/Dockerfile")
  }
}

# Keep the home directory even when the workspace container stops.
# This is the Docker version of what a PVC will do in Kubernetes later.
resource "docker_volume" "home" {
  name = "coder-${data.coder_workspace.me.id}-home"

  # Protect the volume from normal template edits.
  # Deleting the workspace should still remove workspace-owned resources.
  lifecycle {
    ignore_changes = all
  }
}

# This is the actual workspace compute for the Docker version.
# Coder creates or removes this container as the workspace lifecycle changes.
resource "docker_container" "workspace" {
  # Coder templates commonly use start_count to decide whether compute should run.
  # If the workspace is stopped, count becomes 0 and Terraform removes the container.
  count = data.coder_workspace.me.start_count

  image    = docker_image.workspace.name
  name     = "coder-${local.username}-${lower(data.coder_workspace.me.name)}"
  hostname = data.coder_workspace.me.name

  # The init_script starts the Coder agent inside the container.
  # The replace handles local Docker networking when Coder is running on localhost.
  entrypoint = [
    "sh",
    "-c",
    replace(coder_agent.dev.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")
  ]

  env = [
    "CODER_AGENT_TOKEN=${coder_agent.dev.token}"
  ]

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  volumes {
    container_path = "/home/${local.username}"
    volume_name    = docker_volume.home.name
    read_only      = false
  }
}

# Apps show up as clickable buttons in Coder.
# This one opens a sample Python app running inside the workspace.
resource "coder_app" "sample_app" {
  agent_id     = coder_agent.dev.id
  slug         = "sample-app"
  display_name = "Sample App"
  url          = "http://localhost:8000"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  # The app button can show healthy/unhealthy state in Coder.
  # This becomes more useful after the startup script runs a sample web app.
  healthcheck {
    url       = "http://localhost:8000"
    interval  = 5
    threshold = 6
  }
}
```

Useful first exercise:

1. Create `part-02-coder-platform/coder-templates/python-docker/main.tf`.
2. Push it into Coder with the Coder CLI.
3. Create one workspace from the template.
4. Watch the Terraform execution logs in Coder.
5. Stop the workspace and confirm the Docker container is removed.
6. Start it again and confirm the startup script runs cleanly.

Useful second exercise:

1. Copy the template to `part-02-coder-platform/coder-templates/python-kubernetes/main.tf`.
2. Replace the Docker provider and `docker_container` resource with Kubernetes resources.
3. Create a pod, persistent volume claim, and service account for each workspace.
4. Keep the same Coder concepts: parameters, agent, apps, startup script, and resource monitoring.
5. Use Prometheus and Grafana to observe the workspace pod lifecycle.

Learning checkpoint:

- The Coder template is not just "Terraform that creates a container."
- It is the contract between the platform team and developers.
- Parameters define what developers can choose.
- Agents define how Coder connects into the workspace.
- Apps define the useful entry points.
- Compute resources define where the workspace actually runs.
- Resource monitoring and Grafana show whether the template behaves well under real use.

## Deliverables

- `part-02-coder-platform/terraform/coder-ec2`
- `part-02-coder-platform/kubernetes/coder-local`
- `part-02-coder-platform/terraform/coder-eks`
- `part-02-coder-platform/coder-templates/python-docker`
- `part-02-coder-platform/coder-templates/python-kubernetes`
- one Python workspace template
- one local Prometheus/Grafana observability setup
- one Coder workspace health dashboard
- one README explaining local, EC2, and Kubernetes paths

## Through-Line

Coder teaches developer environments as a platform: lifecycle, templates, auth, compute isolation, secrets, resource limits, autoscaling, observability, and cost controls.
