# Agent Instructions

## User Learning Context

The user is learning AWS and has very limited AWS background. When answering AWS-related questions or making AWS infrastructure changes, explain the relevant AWS concepts and tools in practical terms before or alongside the implementation details.

Assume the user may need explanations for concepts such as:

- VPCs, subnets, route tables, NAT gateways, internet gateways, and security groups
- IAM users, roles, policies, instance profiles, IRSA, and EKS Pod Identity
- EC2, EBS, AMIs, user data, and Systems Manager Session Manager
- EKS clusters, managed node groups, add-ons, Kubernetes networking, load balancers, and ingress
- Cost drivers such as EKS control plane charges, NAT gateways, EC2 instance hours, EBS volumes, public IPv4 addresses, and load balancers

Keep explanations detailed enough to teach, but still connected to the user's immediate goal. Prefer concrete examples from this repository over abstract cloud theory.

## Local Machine Context

The user is working from a MacBook Air with an Apple M2 chip.

Assume the host machine is Apple Silicon (`arm64`/`aarch64`) unless the user says otherwise. Most project tooling runs inside a Linux devcontainer, so dependency scripts usually need Linux `arm64` binaries, not macOS binaries. When adding or changing setup scripts, Docker images, CLI downloads, or Kubernetes tooling, account for this architecture explicitly.

Practical implications:

- Prefer multi-architecture Docker images that support `linux/arm64`.
- When downloading CLIs, map architectures carefully:
  - macOS host: `darwin-arm64` or equivalent
  - devcontainer: `linux-arm64`, `Linux_arm64`, or `aarch64`, depending on the vendor
  - x86 fallback: `amd64` or `x86_64`
- Avoid assuming `linux-amd64` binaries will work.
- If a tool only publishes x86 images or binaries, call that out and suggest an Apple Silicon-compatible alternative or an explicit emulation path.
- For Docker Desktop Kubernetes, remember the Kubernetes cluster runs through Docker Desktop on the Mac, while `kubectl`, `helm`, `terraform`, `aws`, `eksctl`, `kind`, and `coder` run from inside the devcontainer.

## VS Code Devcontainer Troubleshooting

VS Code runs with two sides when this repository is opened in a devcontainer:

- The VS Code UI runs on the macOS host.
- Workspace extensions run inside the Linux devcontainer, including Terraform, Kubernetes, Docker, and the OpenAI/Codex extension.

If the VS Code window hangs, the Codex panel spins forever, or the app reports that the window is not responding, do not assume Codex itself is the only problem. First check whether the devcontainer and remote extension host are healthy.

Known issue seen in this repo:

- The HashiCorp Terraform extension can activate before `.devcontainer/setup.sh` has finished installing or exposing `terraform-ls`.
- When that happens, VS Code remote extension logs may show an error like `Unable to launch language server: not found: terraform-ls`.
- This can make the devcontainer session feel broken even though Docker and the Codex extension binary are running.
- The repo pins `terraform.languageServer.path` to `/home/vscode/.local/bin/terraform-ls` so the Terraform extension does not depend on remote extension `PATH` timing.
- The repo also sets `waitFor` to `postCreateCommand` so VS Code waits for `.devcontainer/setup.sh` before attaching and activating remote workspace extensions.
- Codex on Linux expects `bubblewrap`/`bwrap` for reliable sandboxing, so `.devcontainer/setup.sh` installs the Ubuntu `bubblewrap` package. If Codex logs warn that `bubblewrap` is missing, rebuild the devcontainer and verify `bwrap` exists inside it.
- If Codex is still broken after `codex app-server`, `bwrap`, and `terraform-ls` are healthy, check the GitHub Copilot Chat logs. A seen failure is `PendingMigrationError: navigator is now a global in nodejs` from the bundled `GitHub.copilot-chat` extension. Temporarily disable Copilot Chat/background agent features for this workspace to isolate Codex.
- The same `PendingMigrationError` has also been seen from the `openai.chatgpt` extension itself on VS Code Server `1.124.x`. The remote extension host supports a `--supportGlobalNavigator` flag, but this devcontainer launch path did not pass it. `.devcontainer/setup.sh` includes a narrow compatibility patch for the VS Code server `extensionHostProcess.js` global `navigator` guard so Codex can activate.
- Treat that VS Code server patch as a temporary compatibility workaround, not a permanent architecture choice. If Codex breaks again, first verify the current log still shows `PendingMigrationError: navigator is now a global in nodejs` from `openai.chatgpt` or `GitHub.copilot-chat`, then verify the patch was applied inside the active container. If a future VS Code or Codex extension version no longer throws this error, remove the patch from `.devcontainer/setup.sh`.

Useful checks:

- Inspect running devcontainers with `docker ps`.
- Inspect the VS Code server and extension processes with `docker exec <container> ps -eo pid,ppid,stat,etime,comm,args`.
- Read remote extension logs under `/home/vscode/.vscode-server/data/logs/.../exthost*/remoteexthost.log`.
- Verify expected tools exist inside the devcontainer, especially `/home/vscode/.local/bin/terraform-ls`.

Typical recovery steps:

- Reopen or close the frozen VS Code window.
- Run `Dev Containers: Rebuild Container`.
- After the rebuild opens, run `Developer: Reload Window` if extensions still look stuck.
- If Codex still hangs after Terraform is healthy, also check for other remote extension activation errors, such as GitHub Copilot errors.
- If the `navigator` compatibility issue recurs, fully close all VS Code windows for this repo before rebuilding. Multiple stale remote extension hosts in one devcontainer can leave several `codex app-server` processes running and make the UI look broken even after the patch is present.

## Terraform Context

The user has about a year of Terraform experience and understands some basic Terraform functionality. Do not over-explain the absolute basics unless asked, but do explain Terraform concepts when they affect the answer, especially:

- provider configuration
- modules
- variables and outputs
- state
- data sources
- resource dependencies
- `plan` versus `apply`
- lifecycle and destroy behavior
- cost or security implications of Terraform-managed resources

When reviewing or changing Terraform, explain both what the Terraform syntax does and what real AWS resources it creates or changes.

## Plan Requests

When the user says to create an implementation plan, project plan, migration plan, or work plan, export it as a Markdown file.

- Use a `plans/` folder for general implementation or work plans.
- Use a `project-plans/` folder when the plan relates to a new or distinct project.
- Create the folder if it does not already exist.
- Use clear, descriptive kebab-case filenames.
- Make the plan useful as a standalone document, with phases, goals, deliverables, and next steps where appropriate.

Learning material is different:

- Use a `guides/` folder for durable learning guides, study paths, curricula, and conceptual roadmaps.
- If the user says "learning plan", "study guide", "curriculum", or asks for an organized path to learn a topic, prefer `guides/` instead of `plans/`.
- Make guides useful as long-lived reference material, with sequence, checkpoints, concepts, labs, and next steps where appropriate.

If the user only asks to discuss or brainstorm a plan, answer conversationally. If they say "create a plan", "write a plan", "export a plan", or similar, create the `.md` file.

## Communication Style For This Repo

Favor a teaching-oriented style. The user is trying to connect AWS, Terraform, Kubernetes, Coder, and GitHub Actions Runner Controller into a coherent platform engineering skill set.

When possible, make the "so what?" explicit:

- what problem this solves
- what the user learns from it
- what it costs or risks
- how it relates to Coder, EKS, or ARC
- what the next useful layer would be
