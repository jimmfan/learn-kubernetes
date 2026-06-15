# Kubernetes, EKS, Coder, and ARC Learning Lab

This repo is organized around one central learning guide and three hands-on lab parts:

- [Kubernetes Platform Learning Guide](guides/kubernetes-platform-learning-guide.md)

1. [Part 01: Local Kubernetes](part-01-local-kubernetes)
2. [Part 02: Coder Platform](part-02-coder-platform)
3. [Part 03: ARC Runners](part-03-arc-runners)

The guide is the source of truth for sequence, checkpoints, deliverables, and AWS cost guardrails. Each `part-*` folder has its own `walkthrough.md` that acts as the lab manual for that part. The same folders also contain the related manifests, Terraform, Helm values, and future exercises. The goal is practical readiness for Kubernetes, EKS, Coder, and GitHub ARC runner scale sets, not a generic Kubernetes course.

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
  managed-node-group EKS basics for Coder

Part 03: ARC Runners
  GitHub runner inventory
  GitHub-supported ARC runner scale sets locally
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

guides/
  kubernetes-platform-learning-guide.md
                                central learning sequence and checkpoints

part-01-local-kubernetes/
  walkthrough.md                local Kubernetes curriculum and lab guide
  manifests/                    local Kubernetes YAML
  terraform/local-kubernetes/   local Kubernetes Terraform practice

part-02-coder-platform/
  walkthrough.md                Coder platform curriculum and lab guide
  helm-values/                  Coder Helm values starters
  eks/                          EKS eksctl starter config
  terraform/                    Coder template and EKS starter labs

part-03-arc-runners/
  walkthrough.md                ARC curriculum and lab guide
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

It also adds the common `k` alias for `kubectl`.

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

Start with the central guide:

- [Kubernetes Platform Learning Guide](guides/kubernetes-platform-learning-guide.md)

Then use the first walkthrough when the guide sends you into the hands-on lab:

- [Part 01: Local Kubernetes Walkthrough](part-01-local-kubernetes/walkthrough.md)

Then use the matching working folder:

- [Part 01: Local Kubernetes](part-01-local-kubernetes)

After that, move to:

- [Part 02: Coder Platform Walkthrough](part-02-coder-platform/walkthrough.md)
- [Part 03: ARC Runners Walkthrough](part-03-arc-runners/walkthrough.md)

## AWS Cost Safety

Part 01 should cost `$0` because it runs on Docker Desktop.

Parts 02 and 03 can create paid AWS resources when you move into EKS. EKS control planes, NAT gateways, EC2 worker nodes, EBS volumes, public IPv4 addresses, and load balancers can all cost real money. Treat EKS clusters as short-lived learning infrastructure unless you intentionally want them running.

For the first EKS implementation, start with managed node groups. Avoid Karpenter, EKS Auto Mode, advanced autoscaling, and NAT Gateway until the basic Coder or ARC workflow is working and you intentionally want to study those layers.

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
