# ARC On Kubernetes Project Plan

Goal: prepare to lead migration from current GitHub runners to Actions Runner Controller on Kubernetes/EKS.

## Phase 1: Learn Current Runner State

1. Inventory current GitHub runners:
   - where they run
   - labels
   - runner groups
   - installed tools
   - secrets access
   - Docker usage
   - average job duration
   - peak concurrency
2. Identify workflow patterns:
   - build jobs
   - test jobs
   - deploy jobs
   - privileged jobs
   - jobs needing Docker
   - jobs needing cloud credentials
3. Identify migration risks:
   - hardcoded labels
   - local filesystem assumptions
   - long-lived runner state
   - cached dependencies
   - Docker socket usage

Primary learning: what the new platform must preserve.

## Phase 2: ARC Local Lab

1. Create a local Kubernetes cluster with `kind` or `k3d`.
2. Install ARC controller with Helm.
3. Create a GitHub App or PAT for a test repo.
4. Install one runner scale set.
5. Configure a workflow using the scale set name in `runs-on`.
6. Watch runner pods appear, run a job, and disappear.

Primary learning: ARC mechanics without EKS cost.

## Phase 3: Runner Image Lab

1. Build a custom runner image.
2. Add required tools:
   - git
   - Python
   - Node
   - Docker tooling if needed
   - AWS CLI
   - build dependencies
3. Push image to GHCR or ECR.
4. Configure ARC to use that image.
5. Run real sample workflows against it.

Primary learning: replacing snowflake runners with versioned images.

## Phase 4: ARC On EKS Lab

1. Create a small EKS cluster.
2. Install ARC with Helm.
3. Add one runner scale set with `minRunners: 0`.
4. Connect to a test GitHub repo or org.
5. Run a basic CI workflow.
6. Observe:
   - runner pod startup time
   - job logs
   - pod cleanup
   - failed job behavior
   - scaling behavior

Primary learning: real cloud runner operation.

## Phase 5: Production Architecture

1. Decide runner isolation model:
   - repo-level
   - org-level
   - team-level
   - environment-specific
2. Decide node strategy:
   - managed node groups
   - Karpenter
   - Spot vs On-Demand
   - separate node pools for runners
3. Decide Docker strategy:
   - Docker-in-Docker
   - Kubernetes mode
   - no Docker builds
   - external build service
4. Decide auth strategy:
   - GitHub App
   - Kubernetes secrets
   - AWS IRSA / Pod Identity
5. Decide caching strategy:
   - dependency cache
   - Docker layer cache
   - S3/EFS/custom cache
6. Decide observability:
   - metrics
   - logs
   - failed pod retention
   - cost visibility

Primary learning: platform design tradeoffs.

## Phase 6: Migration Plan

1. Pick one low-risk repo.
2. Add ARC runner label beside existing runner label.
3. Migrate one workflow.
4. Compare:
   - duration
   - cost
   - reliability
   - failure modes
5. Migrate more workflows by category.
6. Keep rollback simple:
   - old labels remain available
   - workflow changes are small
   - runner groups stay controlled

Primary learning: safe rollout, not big-bang migration.

## Deliverables

- `part-03-arc-runners/terraform/arc-eks-lab`
- `part-03-arc-runners/kubernetes/arc-local`
- `part-03-arc-runners/runner-images/python-node`
- `docs/current-runner-inventory.md`
- `docs/arc-architecture.md`
- `docs/arc-migration-plan.md`

## Through-Line

ARC teaches CI execution as a platform: ephemeral compute, Kubernetes operators, autoscaling, runner isolation, custom images, workload scheduling, and cost control.
