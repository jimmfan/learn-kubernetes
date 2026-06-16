# Kubernetes, EKS, Coder, and ARC Learning Lab

This repo is a hands-on learning path for Kubernetes platform engineering. Start with local Kubernetes, then layer in Terraform, Helm, Coder, EKS, and GitHub Actions Runner Controller.

The source of truth for the sequence is:

- [Kubernetes Platform Learning Guide](guides/kubernetes-platform-learning-guide.md)

The hands-on parts are:

1. [Part 01: Local Kubernetes](part-01-local-kubernetes)
2. [Part 02: Coder Platform](part-02-coder-platform)
3. [Part 03: ARC Runners](part-03-arc-runners)

Part 01 is the foundation. It should feel boring in a good way: learn how Kubernetes stores desired state, creates Pods through controllers, routes traffic through Services, and explains failures through events, `describe`, and logs. Coder, EKS, and ARC all build on that same object model.

## Learning Path

```text
Part 01: Local Kubernetes
  Docker Desktop Kubernetes
  Kubernetes object model
  kubectl debugging
  YAML manifests
  Terraform with the Kubernetes provider

Part 02: Coder Platform
  Coder locally
  Coder on Kubernetes
  Coder templates as Terraform
  EKS basics with managed node groups for Coder

Part 03: ARC Runners
  GitHub runner inventory
  GitHub-supported ARC runner scale sets locally
  custom runner images
  ARC on EKS
```

The order matters. Local Kubernetes gives you the mental model. Coder turns that model into a developer platform. ARC turns the same model into an ephemeral CI runner platform.

Part 2 and Part 3 are intentionally left for later cleanup. For now, treat Part 1 plus the first two phases of the guide as the polished path.

## Repo Map

```text
.devcontainer/
  devcontainer.json             VS Code devcontainer definition
  setup.sh                      installs CLI tools and prepares kubeconfig

docs/
  devcontainer-setup.md         setup details and troubleshooting

guides/
  kubernetes-platform-learning-guide.md
                                central learning sequence and checkpoints

part-01-local-kubernetes/
  README.md                     Part 1 checklist and namespace map
  kubernetes-universe-map.md    visual concept map for Kubernetes objects
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

Before opening the repo in the devcontainer, make sure Docker Desktop is running and Kubernetes is enabled in Docker Desktop.

Then open this repo in VS Code and run:

```text
Command Palette -> Dev Containers: Rebuild Container
```

The devcontainer runs [.devcontainer/setup.sh](.devcontainer/setup.sh), which installs the CLI tools, copies your host kubeconfig, and adjusts Docker Desktop's local API endpoint so it works from inside the container.

It also adds the common `k` alias for `kubectl`.

Verify the local cluster:

```bash
kubectl config current-context
kubectl get nodes
```

Expected context:

```text
docker-desktop
```

The node list should show one or more `Ready` nodes. Docker Desktop 4.51+ can create either a kubeadm single-node cluster or a kind multi-node cluster, so do not rely on a specific node name. The important checks are the active context and node readiness.

Docker Desktop owns the local Kubernetes cluster. The devcontainer owns the tools. That keeps the host clean while still giving you a real Kubernetes API to practice against.

## Start Here

Start with the central guide:

- [Kubernetes Platform Learning Guide](guides/kubernetes-platform-learning-guide.md)

For Part 1, use the files in this order:

- [Part 01: Local Kubernetes](part-01-local-kubernetes)
- [Kubernetes Universe Map](part-01-local-kubernetes/kubernetes-universe-map.md)
- [Part 01: Local Kubernetes Walkthrough](part-01-local-kubernetes/walkthrough.md)

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

it will fail, because `127.0.0.1` means the container itself. For the standard Docker Desktop Kubernetes endpoint, the setup script rewrites the endpoint to:

```text
https://kubernetes.docker.internal:6443
```

More details are in [docs/devcontainer-setup.md](docs/devcontainer-setup.md).
