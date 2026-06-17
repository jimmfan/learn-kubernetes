# Agent Instructions

## Core Operating Principles

Work in small, reviewable steps.

Before editing files, inspect the relevant configuration and explain what you found. Prefer a short diagnosis and plan before making changes, especially for AWS, Terraform, Kubernetes, Coder, GitHub Actions Runner Controller, or devcontainer work.

Do not rewrite unrelated files. Do not make broad refactors unless explicitly asked. Prefer the smallest safe change that solves the immediate problem.

When making infrastructure changes, explain:

* what problem the change solves
* where the setting lives
* what AWS, Kubernetes, Terraform, Coder, or GitHub resource is affected
* what the cost, security, or operational risk is
* how to validate the change safely

Do not run or suggest destructive commands unless explicitly asked. Be especially careful with commands or changes involving:

* `terraform apply`
* `terraform destroy`
* Kubernetes deletion
* EBS volumes
* IAM policies
* security groups
* route tables
* lifecycle settings
* load balancers
* NAT gateways
* public IP addresses

When uncertain, say what is known, what is assumed, and how to verify it.

## User Learning Context

The user is learning AWS, Kubernetes, EKS, Coder, and platform engineering. The user has limited AWS and Kubernetes background, but has some Terraform experience.

When answering AWS, Kubernetes, Coder, or infrastructure questions, explain the practical concept before or alongside the implementation detail. Keep explanations connected to the user's immediate goal. Prefer concrete examples from this repository over abstract cloud theory.

Assume the user may need explanations for:

* VPCs, subnets, route tables, NAT gateways, internet gateways, and security groups
* IAM users, roles, policies, instance profiles, IRSA, and EKS Pod Identity
* EC2, EBS, AMIs, user data, and Systems Manager Session Manager
* EKS clusters, managed node groups, add-ons, Kubernetes networking, services, load balancers, and ingress
* Kubernetes pods, deployments, services, namespaces, labels, storage classes, persistent volumes, and persistent volume claims
* Coder control plane resources, workspace templates, devcontainers, home volumes, and workspace startup behavior
* GitHub Actions Runner Controller concepts such as runner scale sets, listener pods, runner pods, GitHub authentication, and autoscaling
* Cost drivers such as EKS control plane charges, NAT gateways, EC2 instance hours, EBS volumes, public IPv4 addresses, and load balancers

Keep explanations detailed enough to teach, but avoid over-explaining basic Terraform unless the concept affects the change.

## Repository Context

This repository is used for platform engineering work involving some combination of:

* local development from a VS Code devcontainer
* Terraform-managed infrastructure
* AWS resources
* Kubernetes or EKS
* Coder workspace templates or supporting platform components
* developer tooling such as `kubectl`, `helm`, `terraform`, `aws`, `eksctl`, `coder`, and related CLIs

When reviewing the repo, first determine whether a setting is managed by:

* Terraform
* Helm values
* raw Kubernetes YAML
* devcontainer configuration
* shell setup scripts
* AWS console/manual configuration
* Coder template configuration
* GitHub Actions or workflow configuration

When explaining a change, explicitly say where the setting lives.

For detailed devcontainer and Codex troubleshooting history, see:

* `docs/devcontainer-troubleshooting.md`
* `docs/codex-troubleshooting.md`

## Local Machine Context

The user is working from a MacBook Air with an Apple M2 chip.

Assume the host machine is Apple Silicon, meaning `arm64` or `aarch64`, unless the user says otherwise. Most project tooling runs inside a Linux devcontainer, so dependency scripts usually need Linux `arm64` binaries, not macOS binaries.

When adding or changing setup scripts, Docker images, CLI downloads, or Kubernetes tooling, account for architecture explicitly.

Practical implications:

* Prefer multi-architecture Docker images that support `linux/arm64`.
* When downloading CLIs, map architectures carefully:

  * macOS host: `darwin-arm64` or equivalent
  * devcontainer: `linux-arm64`, `Linux_arm64`, or `aarch64`, depending on the vendor
  * x86 fallback: `amd64` or `x86_64`
* Avoid assuming `linux-amd64` binaries will work.
* If a tool only publishes x86 images or binaries, call that out and suggest an Apple Silicon-compatible alternative or an explicit emulation path.
* For Docker Desktop Kubernetes, remember the Kubernetes cluster runs through Docker Desktop on the Mac, while `kubectl`, `helm`, `terraform`, `aws`, `eksctl`, `kind`, and `coder` usually run from inside the devcontainer.

## Python Context

Prefer `uv` for Python dependency management when applicable.

When writing Python:

* use clear names
* prefer type hints for non-trivial functions
* keep functions small
* add or update tests when changing behavior
* avoid unnecessary dependencies
* prefer standard library solutions when reasonable

If the code interacts with AWS, Terraform outputs, Kubernetes, or shell commands, include practical error handling and clear messages.

## Terraform Context

The user has about a year of Terraform experience and understands basic Terraform functionality. Do not over-explain absolute basics unless asked, but do explain Terraform concepts when they affect the answer.

Explain Terraform concepts when relevant, especially:

* provider configuration
* modules
* variables and outputs
* state
* data sources
* resource dependencies
* `plan` versus `apply`
* lifecycle and destroy behavior
* cost or security implications of Terraform-managed resources

When reviewing or changing Terraform, explain both:

1. what the Terraform syntax does
2. what real AWS, Kubernetes, or Coder resources it creates or changes

Before changing Terraform:

* inspect the current resources, variables, providers, modules, and outputs
* identify the likely state boundary
* avoid changing lifecycle behavior unless explicitly requested
* call out whether a change may force replacement
* suggest `terraform plan` validation before apply

Be especially careful with:

* `prevent_destroy`
* `ignore_changes`
* EBS volume lifecycle
* Kubernetes storage classes
* IAM permissions
* security groups
* route tables
* NAT gateways
* load balancers
* public IP addresses

## Kubernetes and EKS Context

Assume the user is still building Kubernetes intuition.

When explaining Kubernetes, connect concepts to concrete examples:

* A pod is the smallest running unit.
* A deployment keeps pods running.
* A service gives stable network access to pods.
* An ingress or load balancer exposes traffic.
* A storage class describes how persistent storage is provisioned.
* A persistent volume claim is a pod's request for durable storage.
* A node is the worker machine where pods run.

When reviewing Kubernetes or EKS changes, explain:

* whether the change affects the cluster, nodes, pods, networking, storage, or IAM
* whether it is namespaced or cluster-wide
* whether it is managed by Terraform, Helm, raw YAML, or AWS
* how to inspect the live state with `kubectl`
* how the change relates to Coder workspaces or ARC runners if relevant

Prefer safe inspection commands before mutation commands.

## Coder Context

When working on Coder-related files, explain how changes affect:

* the Coder control plane
* workspace templates
* workspace startup
* devcontainers
* persistent home volumes
* workspace images
* user experience for developers
* AWS or Kubernetes resources behind the workspace

For workspace templates, be especially careful with:

* persistent storage
* home volume sizing
* workspace image architecture
* startup scripts
* environment variables
* secrets
* IAM or cloud credentials
* Docker-in-Docker or Docker socket behavior
* devcontainer compatibility

If a Coder issue appears to be a UI problem, first check whether the workspace, devcontainer, VS Code remote extension host, and required binaries are healthy.

## Plan and Documentation Requests

When the user says to create an implementation plan, project plan, migration plan, or work plan, export it as a Markdown file.

Use:

* `plans/` for general implementation or work plans
* `project-plans/` for new or distinct projects
* `guides/` for learning guides, study paths, curricula, and conceptual roadmaps
* `docs/` for durable project documentation that is not specifically a plan or guide

Create the folder if it does not already exist.

Use clear, descriptive kebab-case filenames.

Make plans useful as standalone documents, with phases, goals, deliverables, risks, validation steps, and next actions where appropriate.

Learning material is different:

* If the user says "learning plan", "study guide", "curriculum", or asks for an organized path to learn a topic, prefer `guides/` instead of `plans/`.
* Make guides useful as long-lived reference material, with sequence, checkpoints, concepts, labs, and next steps.

If the user only asks to discuss or brainstorm a plan, answer conversationally. If they say "create a plan", "write a plan", "export a plan", or similar, create the `.md` file.

## Communication Style

Favor a teaching-oriented style. The user is trying to connect AWS, Terraform, Kubernetes, Coder, and GitHub Actions Runner Controller into a coherent platform engineering skill set.

When possible, make the "so what?" explicit:

* what problem this solves
* what the user learns from it
* what it costs or risks
* how it relates to Coder, EKS, or ARC
* what the next useful layer would be

Prefer concrete commands, examples, and repo-specific explanations.

Do not be vague. Prefer practical next steps.
