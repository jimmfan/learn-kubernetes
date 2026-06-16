# Devcontainer Setup

This project uses Docker Desktop Kubernetes as the local cluster and a VS Code devcontainer as the tooling environment.

The important split is:

```text
Docker Desktop Kubernetes = local cluster on the Mac
Devcontainer = kubectl, Terraform, Helm, AWS, GitHub, Coder, and helper tools
```

The devcontainer does not create the main Kubernetes cluster for Part 1. It connects to the Docker Desktop cluster running on the Mac host.

Docker Desktop 4.51+ can provision Kubernetes in more than one local shape: kubeadm for a single-node cluster or kind for a multi-node cluster. This repo cares about the kubeconfig context and node readiness, not an exact node name. The endpoint rewrite below is for the common Docker Desktop kubeconfig address `https://127.0.0.1:6443`.

## Files

- [../.devcontainer/devcontainer.json](../.devcontainer/devcontainer.json) defines the container.
- [../.devcontainer/setup.sh](../.devcontainer/setup.sh) installs the project CLI tools and prepares kubeconfig.

## What The Setup Script Does

The setup script:

- Installs base utilities: `curl`, `git`, `jq`, `make`, `unzip`, `less`, `nano`, `tree`, `dnsutils`, `netcat`, certificates, and GPG tooling.
- Installs `bubblewrap` for reliable Codex sandboxing inside the Linux devcontainer.
- Installs `kubectl` for talking to Kubernetes clusters.
- Installs `helm` for Coder, ARC, and other Kubernetes chart installs.
- Installs `terraform` for the local Kubernetes and EKS practice modules.
- Installs `terraform-ls` for Terraform language-server support in VS Code.
- Installs `tflint` for Terraform linting.
- Installs `yq` for reading and editing YAML from the command line.
- Installs `aws` for AWS account access and EKS kubeconfig updates.
- Installs `gh` for GitHub repo, workflow, and runner inventory tasks.
- Installs `eksctl` for optional later EKS Auto Mode experiments.
- Installs `kind` for local ARC experiments that need a disposable Kubernetes cluster.
- Installs `coder` for Coder template and workspace workflows.
- Copies the host kubeconfig from `/tmp/host-kube/config` into the devcontainer.
- Rewrites Docker Desktop Kubernetes API endpoints that do not work from inside the container.
- Adds the `k` alias and bash completion for `kubectl`.
- Applies a narrow VS Code Server compatibility patch for a known `navigator is now a global in nodejs` extension-host issue.
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
| `eksctl` | Creating optional EKS clusters from YAML, including the later Auto Mode example. |
| `kind` | Running a throwaway local Kubernetes cluster from inside the devcontainer, useful for ARC labs. This is separate from Docker Desktop's own Kubernetes provisioning. |
| `coder` | Pushing Coder templates and interacting with Coder workspaces. |
| `bwrap` | Bubblewrap sandbox helper used by Codex on Linux. |

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
kubectl config current-context
kubectl get nodes -L kubernetes.io/arch -o wide
```

Expected context:

```text
docker-desktop
```

Expected node state:

```text
At least one node is Ready.
```

The node name can vary by Docker Desktop Kubernetes provisioning method. A kubeadm single-node cluster may show `docker-desktop`; a kind-based Docker Desktop cluster may show different names.

Check the API endpoint:

```bash
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'; echo
```

Expected inside the devcontainer for the standard Docker Desktop endpoint rewrite:

```text
https://kubernetes.docker.internal:6443
```

## Why The Endpoint Rewrite Exists

Docker Desktop kubeconfig may point at:

```text
https://127.0.0.1:6443
```

Inside a devcontainer, `127.0.0.1` refers to the container, not the Mac host. That makes `kubectl` look in the wrong place.

For kubeconfigs that point at `https://127.0.0.1:6443`, the working endpoint from inside this devcontainer is:

```text
https://kubernetes.docker.internal:6443
```

That hostname also matches Docker Desktop's Kubernetes API certificate. If Docker Desktop creates a different local endpoint, first inspect the generated kubeconfig and verify what works from inside the devcontainer before hand-editing it.

## Troubleshooting

### No `docker-desktop` Context

Example:

```text
error: current-context is not set
```

or `kubectl config get-contexts` does not list `docker-desktop`.

Cause:

Docker Desktop Kubernetes is not enabled on the Mac, or the host kubeconfig was not mounted into the devcontainer.

Fix:

1. Enable Kubernetes in Docker Desktop.
2. Verify on the Mac host that `~/.kube/config` has a `docker-desktop` context.
3. Rebuild the devcontainer so `.devcontainer/setup.sh` can copy `/tmp/host-kube/config` again.

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

### Terraform Language Server Not Found

Example:

```text
Unable to launch language server: not found: terraform-ls
```

Cause:

The Terraform VS Code extension started before the setup script finished installing `terraform-ls`, or the extension did not see the expected PATH.

Fix:

This repo pins the Terraform language server path to:

```text
/home/vscode/.local/bin/terraform-ls
```

Rebuild the devcontainer and then verify:

```bash
test -x /home/vscode/.local/bin/terraform-ls
terraform-ls version
```

### Codex Sandbox Warning

Example:

```text
bubblewrap is missing
```

Cause:

Codex on Linux expects `bubblewrap`/`bwrap` for reliable sandboxing, but the package is missing in the active container.

Fix:

Rebuild the devcontainer and verify:

```bash
command -v bwrap
```

### VS Code `navigator` Extension-Host Error

Example:

```text
PendingMigrationError: navigator is now a global in nodejs
```

Cause:

Some VS Code Server and extension combinations can throw this during remote extension activation. The setup script includes a narrow compatibility patch for the VS Code Server extension host process.

Fix:

Fully close VS Code windows for this repo, rebuild the devcontainer, and check the remote extension logs again. Treat this as a temporary compatibility workaround; if future VS Code or extension versions no longer throw this error, remove the patch from `.devcontainer/setup.sh`.

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
