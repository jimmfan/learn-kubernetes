# Devcontainer Setup

This project uses Docker Desktop Kubernetes as the cluster and a VS Code devcontainer as the tooling environment.

The important split is:

```text
Docker Desktop Kubernetes = cluster
Devcontainer = kubectl and tools
```

The devcontainer does not create a Kubernetes cluster. It connects to the Docker Desktop cluster running on the Mac host.

## Files

- [../.devcontainer/devcontainer.json](../.devcontainer/devcontainer.json) defines the container.
- [../.devcontainer/setup.sh](../.devcontainer/setup.sh) installs the project CLI tools and prepares kubeconfig.

## What The Setup Script Does

The setup script:

- Installs base utilities: `curl`, `git`, `jq`, `make`, `unzip`, certificates, and GPG tooling.
- Installs `kubectl` for talking to Kubernetes clusters.
- Installs `helm` for Coder, ARC, and other Kubernetes chart installs.
- Installs `terraform` for the local Kubernetes and EKS practice modules.
- Installs `terraform-ls` for Terraform language-server support in VS Code.
- Installs `tflint` for Terraform linting.
- Installs `yq` for reading and editing YAML from the command line.
- Installs `aws` for AWS account access and EKS kubeconfig updates.
- Installs `gh` for GitHub repo, workflow, and runner inventory tasks.
- Installs `eksctl` for the EKS Auto Mode starter.
- Installs `kind` for local ARC experiments that need a disposable Kubernetes cluster.
- Installs `coder` for Coder template and workspace workflows.
- Copies the host kubeconfig from `/tmp/host-kube/config` into the devcontainer.
- Rewrites Docker Desktop Kubernetes API endpoints that do not work from inside the container.
- Prints tool versions, the current cluster endpoint, and available contexts.

## Tool Map

| Tool | Used For |
|------|----------|
| `kubectl` | Inspecting and changing Kubernetes resources in local Docker Desktop, kind, or EKS clusters. |
| `helm` | Installing packaged Kubernetes apps such as Coder and Actions Runner Controller. |
| `terraform` | Creating Kubernetes resources locally and AWS/EKS infrastructure later. |
| `terraform-ls` | Terraform language server used by the HashiCorp Terraform VS Code extension. |
| `tflint` | Linting Terraform for provider-specific mistakes and style issues. |
| `yq` | Querying and editing YAML files such as Kubernetes manifests and Helm values. |
| `aws` | Authenticating to AWS and running `aws eks update-kubeconfig`. |
| `gh` | Inspecting GitHub repositories, workflows, and runner setup during ARC work. |
| `eksctl` | Creating the EKS Auto Mode starter cluster from YAML. |
| `kind` | Running a throwaway local Kubernetes cluster, useful for ARC labs. |
| `coder` | Pushing Coder templates and interacting with Coder workspaces. |

For AWS learning: `aws` is the general AWS CLI, while `eksctl` is a Kubernetes/EKS-focused helper that can create and delete EKS clusters from a simpler YAML file. Terraform overlaps with `eksctl`, but teaches the infrastructure-as-code model you will use for more production-shaped AWS work.

## VS Code Extensions

The devcontainer recommends these extensions:

| Extension | Used For |
|-----------|----------|
| `HashiCorp.terraform` | Official Terraform syntax highlighting, formatting, validation, and language-server integration. |
| `ms-kubernetes-tools.vscode-kubernetes-tools` | Kubernetes manifest help, cluster browsing, and `kubectl`-oriented workflows. |
| `redhat.vscode-yaml` | YAML validation and editing support for Kubernetes manifests, Helm values, and GitHub Actions workflows. |
| `github.vscode-github-actions` | GitHub Actions workflow editing, useful for ARC runner migration labs. |
| `ms-azuretools.vscode-docker` | Dockerfile and container workflow support for Coder and runner images. |
| `openai.chatgpt` | ChatGPT extension support inside the devcontainer. |

## Rebuild

In VS Code:

```text
Command Palette -> Dev Containers: Rebuild Container
```

## Verify

```bash
kubectl config get-contexts
kubectl get nodes
```

Expected node:

```text
docker-desktop
```

Check the API endpoint:

```bash
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'; echo
```

Expected inside the devcontainer:

```text
https://kubernetes.docker.internal:6443
```

## Why The Endpoint Rewrite Exists

Docker Desktop kubeconfig may point at:

```text
https://127.0.0.1:6443
```

Inside a devcontainer, `127.0.0.1` refers to the container, not the Mac host. That makes `kubectl` look in the wrong place.

The working endpoint is:

```text
https://kubernetes.docker.internal:6443
```

That hostname also matches Docker Desktop's Kubernetes API certificate.

## Troubleshooting

### Docker Socket Permission Error

Example:

```text
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

Cause:

The devcontainer user cannot access the Docker socket.

Fix:

Use the Docker-outside-of-Docker feature in [../.devcontainer/devcontainer.json](../.devcontainer/devcontainer.json):

```json
"ghcr.io/devcontainers/features/docker-outside-of-docker:1": {}
```

### `127.0.0.1:6443` Refused

Example:

```text
The connection to the server 127.0.0.1:6443 was refused
```

Cause:

Inside the devcontainer, `127.0.0.1` refers to the container itself.

Fix:

Use:

```text
https://kubernetes.docker.internal:6443
```

### TLS Certificate Hostname Error

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
