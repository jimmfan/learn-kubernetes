# Local Kubernetes Lab with Docker Desktop + Devcontainer

This README documents a working local Kubernetes lab on an M2 MacBook Air using:

- Docker Desktop Kubernetes as the local cluster
- VS Code Devcontainer as the tooling environment
- `kubectl` installed inside the devcontainer
- No global Kubernetes tooling required on the host

## EKS + Coder Learning Track

This repo now includes a practical path for learning AWS EKS in the context of a Coder deployment:

- [EKS + Coder Learning Plan](docs/eks-coder-learning-plan.md)
- [Local hello Kubernetes workload](examples/local/hello-k8s.yaml)
- [Local Coder Helm values](examples/coder/values-local.yaml)
- [EKS Coder Helm values starter](examples/coder/values-eks.yaml)
- [EKS Auto Mode `eksctl` starter](examples/eks/eksctl-auto-mode.yaml)
- [Terraform local Kubernetes practice](examples/terraform/local-kubernetes)
- [Terraform Coder template practice](examples/terraform/coder-template-kubernetes)
- [Terraform EKS starter](examples/terraform/eks-starter)

Start locally, get fluent with the Kubernetes primitives, practice expressing the same ideas in Terraform, then move the mental model into EKS where networking, identity, storage, load balancing, and cost become the important architecture questions.

---

## Architecture Overview

```text
Mac host
  └── Docker Desktop
        └── Kubernetes cluster: docker-desktop

VS Code Devcontainer
  └── kubectl (+ tools)
        └── connects to Docker Desktop Kubernetes
```

The Kubernetes cluster runs in Docker Desktop on the host.  
The devcontainer is only the client/tooling environment.

---

## Why This Setup

This setup avoids nested Docker/Kubernetes complexity while keeping tooling isolated from the global Mac environment.

Final approach:

```text
Docker Desktop Kubernetes = cluster
Devcontainer = kubectl/tooling
```

Benefits:

- No global Kubernetes tooling required
- Reproducible tooling environment
- Clean separation between cluster runtime and development tooling
- Better alignment with real DevSecOps workflows

---

## Prerequisites

- Docker Desktop installed
- Kubernetes enabled in Docker Desktop
- VS Code with Dev Containers extension

---

## Project Structure

```text
learn-k8s/
  .devcontainer/
    devcontainer.json
    setup.sh
  README.md
```

---

# Devcontainer Configuration

Create:

## `.devcontainer/devcontainer.json`

```json
{
  "name": "k8s-dev",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",

  "features": {
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {}
  },

  "mounts": [
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind",
    "source=${localEnv:HOME}/.kube,target=/tmp/host-kube,type=bind,readonly"
  ],

  "remoteEnv": {
    "PATH": "${containerEnv:HOME}/.local/bin:${containerEnv:PATH}"
  },

  "postCreateCommand": "bash .devcontainer/setup.sh",

  "customizations": {
    "vscode": {
      "extensions": [
        "ms-kubernetes-tools.vscode-kubernetes-tools"
      ]
    }
  }
}
```

---

# Setup Script

Create:

## `.devcontainer/setup.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

install_dir="$HOME/.local/bin"
mkdir -p "$install_dir"

export PATH="$install_dir:$PATH"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

# Detect architecture
arch="$(uname -m)"
case "$arch" in
  x86_64) arch="amd64" ;;
  aarch64|arm64) arch="arm64" ;;
  *) echo "Unsupported architecture: $arch"; exit 1 ;;
esac

# Install kubectl
kubectl_version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
curl -fsSL -o "$tmp_dir/kubectl" \
  "https://dl.k8s.io/release/${kubectl_version}/bin/linux/${arch}/kubectl"

install -m 0755 "$tmp_dir/kubectl" "$install_dir/kubectl"

# ---- Kubeconfig fix ----

mkdir -p "$HOME/.kube"

if [ -f /tmp/host-kube/config ]; then
  cp /tmp/host-kube/config "$HOME/.kube/config"

  # Fix localhost issue inside container
  sed -i \
    's#https://127.0.0.1:6443#https://kubernetes.docker.internal:6443#g' \
    "$HOME/.kube/config"

  sed -i \
    's#https://host.docker.internal:6443#https://kubernetes.docker.internal:6443#g' \
    "$HOME/.kube/config"
fi

echo "kubectl:"
kubectl version --client

echo "Cluster endpoint:"
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'; echo
```

---

# Rebuild Devcontainer

In VS Code:

```text
Command Palette → Dev Containers: Rebuild Container
```

---

# Verify Setup

```bash
kubectl config get-contexts
kubectl get nodes
```

Expected:

```text
NAME             STATUS   ROLES           AGE   VERSION
docker-desktop   Ready    control-plane   ...   v1.30.5
```

Verify endpoint:

```bash
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'; echo
```

Expected:

```text
https://kubernetes.docker.internal:6443
```

---

# Key Fix: Localhost Problem

Docker Desktop kubeconfig may use:

```text
https://127.0.0.1:6443
```

Inside a devcontainer, that points to the container itself.

Fix:

```text
https://kubernetes.docker.internal:6443
```

This matches the TLS certificate.

---

# Kubernetes Learning Walkthrough

## Create Namespace

```bash
kubectl create namespace lab
kubectl config set-context --current --namespace=lab
```

A namespace is a logical workspace inside the cluster.

---

## Deploy Nginx

```bash
kubectl create deployment nginx-demo --image=nginx:1.27
kubectl get pods
```

This creates:

```text
Deployment → ReplicaSet → Pods → Containers
```

The Deployment declares the desired state and Kubernetes reconciles the cluster to match it.

---

## Scale Deployment

```bash
kubectl scale deployment nginx-demo --replicas=3
kubectl get pods
```

Kubernetes automatically creates additional Pods to match the desired replica count.

---

## Expose Service

```bash
kubectl expose deployment nginx-demo --port=80 --type=ClusterIP
kubectl get svc
```

A Service gives Pods a stable network endpoint and load balances traffic across matching Pods.

---

## Access App

```bash
kubectl port-forward svc/nginx-demo 8080:80
```

Open in browser:

```text
http://localhost:8080
```

This creates a temporary tunnel:

```text
localhost:8080
  → Kubernetes Service
    → Pods
```

---

## View Resources

```bash
kubectl get all
```

Shows common resources:

- Pods
- Services
- Deployments
- ReplicaSets

---

## Describe Deployment

```bash
kubectl describe deployment nginx-demo
```

Useful for:

- labels
- selectors
- rollout status
- events
- replica counts

---

## Describe Pod

```bash
kubectl get pods
kubectl describe pod <pod-name>
```

Useful for:

- scheduling issues
- image pull failures
- events
- container status
- node placement

---

## View Logs

```bash
kubectl logs <pod-name>
```

For multi-container Pods:

```bash
kubectl logs <pod-name> -c <container-name>
```

---

## Self-Healing

Delete a Pod:

```bash
kubectl delete pod <pod-name>
kubectl get pods
```

Kubernetes automatically recreates the Pod because the Deployment still wants the desired replica count.

---

## Rolling Update

```bash
kubectl set image deployment/nginx-demo nginx=nginx:1.26
kubectl rollout status deployment nginx-demo
```

Kubernetes gradually replaces old Pods with new Pods.

---

## Rollback

```bash
kubectl rollout undo deployment nginx-demo
```

Reverts the Deployment to the previous version.

---

## Cleanup

```bash
kubectl delete namespace lab
```

Deletes all resources inside the namespace.

---

# Core Mental Model

```text
Deployment → ReplicaSet → Pods → Containers

Service → routes traffic to Pods
```

---

# Mapping to EKS

| Local | EKS |
|------|------|
| docker-desktop | EKS cluster |
| local node | EC2 / Fargate |
| ClusterIP | ClusterIP |
| port-forward | ALB / LoadBalancer |
| kubeconfig | AWS CLI kubeconfig |

The Kubernetes resources remain mostly the same.

The main differences in EKS are surrounding AWS infrastructure:

- VPC
- IAM
- Security groups
- Load balancers
- EBS
- CloudWatch
- Terraform

---

# Troubleshooting

## Docker Socket Permission Error

Example:

```text
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

Cause:

The devcontainer user cannot access the Docker socket.

Fix:

Use:

```json
"ghcr.io/devcontainers/features/docker-outside-of-docker:1"
```

instead of Docker-in-Docker.

---

## `127.0.0.1:6443` Refused

Example:

```text
The connection to the server 127.0.0.1:6443 was refused
```

Cause:

Inside the devcontainer, `127.0.0.1` refers to the container itself, not the Mac host.

Fix:

```text
https://kubernetes.docker.internal:6443
```

---

## TLS Certificate Hostname Error

Example:

```text
x509: certificate is valid for docker-for-desktop, kubernetes, kubernetes.default, kubernetes.docker.internal, localhost, vm.docker.internal, not host.docker.internal
```

Cause:

The Kubernetes API certificate does not include `host.docker.internal`.

Fix:

Use:

```text
https://kubernetes.docker.internal:6443
```

not:

```text
https://host.docker.internal:6443
```

---

# Recommended Next Topics

- ConfigMaps & Secrets
- Resource requests and limits
- Readiness and liveness probes
- Ingress
- Helm
- EKS with Terraform
- AWS Load Balancer Controller
- IRSA / EKS Pod Identity
- EBS CSI driver
- Cluster logging and monitoring
