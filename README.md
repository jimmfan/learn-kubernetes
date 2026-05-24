# Kubernetes, EKS, Coder, and ARC Learning Lab

This repo is organized as a three-part hands-on learning path:

1. [Part 01: Local Kubernetes](part-01-local-kubernetes)
2. [Part 02: Coder Platform](part-02-coder-platform)
3. [Part 03: ARC Runners](part-03-arc-runners)

The project plans in [project-plans](project-plans) are the curriculum. The `part-*` folders are the working areas where the related manifests, Terraform, Helm values, and future exercises live.

## Learning Path

```text
Part 01: Local Kubernetes
  Docker Desktop Kubernetes
  kubectl debugging
  YAML manifests
  Terraform with the Kubernetes provider

Part 02: Coder Platform
  Coder locally
  Coder on Kubernetes
  Coder templates as Terraform
  EKS basics for Coder

Part 03: ARC Runners
  GitHub runner inventory
  Actions Runner Controller locally
  custom runner images
  ARC on EKS
```

The order matters. Local Kubernetes gives you the mental model. Coder turns that model into a developer platform. ARC turns the same model into an ephemeral CI runner platform.

## Repo Map

```text
.devcontainer/
  devcontainer.json             VS Code devcontainer definition
  setup.sh                      installs kubectl and prepares kubeconfig

docs/
  devcontainer-setup.md         setup details and troubleshooting
  eks-coder-learning-plan.md    longer EKS + Coder learning roadmap

project-plans/
  local-kubernetes-walkthrough.md
  coder-platform-project.md
  arc-on-kubernetes-project.md

part-01-local-kubernetes/
  manifests/                    local Kubernetes YAML
  terraform/local-kubernetes/   local Kubernetes Terraform practice

part-02-coder-platform/
  helm-values/                  Coder Helm values starters
  eks/                          EKS eksctl starter config
  terraform/                    Coder template and EKS starter labs

part-03-arc-runners/
  kubernetes/                   future ARC local lab
  terraform/                    future ARC EKS lab
  runner-images/                future custom runner images
```

## Devcontainer Quick Start

Open this repo in VS Code, then run:

```text
Command Palette -> Dev Containers: Rebuild Container
```

The devcontainer runs [.devcontainer/setup.sh](.devcontainer/setup.sh), which installs `kubectl`, copies your host kubeconfig, and adjusts Docker Desktop's local API endpoint so it works from inside the container.

Verify the local cluster:

```bash
kubectl config get-contexts
kubectl get nodes
```

Expected cluster:

```text
docker-desktop
```

Docker Desktop owns the local Kubernetes cluster. The devcontainer owns the tools. That keeps the host clean while still giving you a real Kubernetes API to practice against.

## Start Here

Start with the first project plan:

- [Local Kubernetes Walkthrough](project-plans/local-kubernetes-walkthrough.md)

Then use the matching working folder:

- [Part 01: Local Kubernetes](part-01-local-kubernetes)

After that, move to:

- [Coder Platform Project Plan](project-plans/coder-platform-project.md)
- [ARC On Kubernetes Project Plan](project-plans/arc-on-kubernetes-project.md)

## AWS Cost Safety

Part 01 should cost `$0` because it runs on Docker Desktop.

Parts 02 and 03 can create paid AWS resources when you move into EKS. EKS control planes, NAT gateways, EC2 worker nodes, EBS volumes, public IPv4 addresses, and load balancers can all cost real money. Treat EKS clusters as short-lived learning infrastructure unless you intentionally want them running.

## Common Local Fix

If `kubectl` tries to connect to this from inside the devcontainer:

```text
https://127.0.0.1:6443
```

it will fail, because `127.0.0.1` means the container itself. The setup script rewrites the endpoint to:

```text
https://kubernetes.docker.internal:6443
```

More details are in [docs/devcontainer-setup.md](docs/devcontainer-setup.md).
