# ARC Runners Walkthrough

Goal: prepare to lead migration from current GitHub runners to Actions Runner Controller on Kubernetes/EKS.

Scope: focus on GitHub-supported ARC runner scale sets. Do not build this around older legacy `RunnerDeployment` examples.

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
2. Install the GitHub-supported ARC controller with Helm.
3. Create a GitHub App or PAT for a test repo.
4. Install one GitHub-supported runner scale set.
5. Configure a workflow using the scale set name in `runs-on`.
6. Watch runner pods appear, run a job, and disappear.

Primary learning: ARC mechanics without EKS cost.

## ARC Runs-On Mapping

The runner scale set installation name maps to the workflow `runs-on` value.

If the scale set is installed as `arc-runner-set`, the workflow uses:

```yaml
jobs:
  build:
    runs-on: arc-runner-set
    steps:
      - uses: actions/checkout@v4
```

GitHub queues the job for that runner label, ARC creates an ephemeral runner pod, the pod registers with GitHub, runs the job, and then exits.

## Debugging Checklist

Run this when a runner does not appear, a job is queued too long, or a runner pod fails:

```bash
kubectl get pods -A
kubectl get events -A --sort-by=.lastTimestamp
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace>
kubectl exec -it <pod> -n <namespace> -- sh
kubectl get svc -A
kubectl get ingress -A
kubectl get pvc -A
```

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

1. Create a small EKS cluster with managed node groups first.
2. Avoid Karpenter, EKS Auto Mode, and advanced autoscaling until later optional sections.
3. Avoid NAT Gateway unless the runner lab truly needs private subnet egress.
4. Run the EKS smoke test before installing ARC.
5. Deploy a simple hello app before installing platform tooling.
6. Install ARC with Helm.
7. Add one runner scale set with `minRunners: 0`.
8. Connect to a test GitHub repo or org.
9. Run a basic CI workflow.
10. Observe:
   - runner pod startup time
   - job logs
   - pod cleanup
   - failed job behavior
   - scaling behavior

Primary learning: real cloud runner operation.

## EKS Smoke Test Before ARC

Do this before installing ARC on EKS:

```bash
aws sts get-caller-identity
aws eks update-kubeconfig --name <cluster> --region <region>
kubectl get nodes
kubectl get pods -A
kubectl auth can-i get pods -A
kubectl apply -f part-01-local-kubernetes/manifests/hello-k8s.yaml
kubectl get all -n hello
```

If the hello app cannot run, ARC runner pods will not be reliable either.

## Apple Silicon Checks

Before building runner images or downloading tools:

```bash
uname -m
docker buildx ls
kubectl get nodes -o wide
```

The MacBook Air M2 and devcontainer path should use `linux/arm64` compatible images and binaries where applicable.

## EKS Cost Traps

- EKS control plane hourly charges
- EC2 node hours while waiting for jobs
- NAT Gateway hourly and data processing charges
- EBS volumes and image cache storage
- public IPv4 address charges
- load balancers from test services or ingress

Start with managed node groups and simple capacity. Add Karpenter, Spot, or more advanced autoscaling only after the runner scale set mechanics are understood.

## Phase 5: Production Architecture

1. Decide runner isolation model:
   - repo-level
   - org-level
   - team-level
   - environment-specific
2. Decide node strategy:
   - managed node groups
   - Karpenter later
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

## What I Should Be Able To Explain

- What pod runs the GitHub job
- How GitHub finds the runner
- What the runner scale set does
- Where secrets live
- Why a runner pod failed to start
- How EKS node capacity affects job startup time
