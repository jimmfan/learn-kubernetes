# Part 03: ARC Runners

Walkthrough: [ARC Runners Walkthrough](walkthrough.md)

Goal: learn how GitHub Actions Runner Controller runs CI jobs as ephemeral Kubernetes workloads, then map that model to EKS.

This track focuses on GitHub-supported ARC runner scale sets, not older legacy `RunnerDeployment` examples.

## What This Part Teaches

- ARC controller and runner scale sets
- GitHub runner labels and workflow migration
- Ephemeral runner pods
- Custom runner images
- Kubernetes scheduling and isolation for CI
- EKS node strategy, IAM, secrets, caching, observability, and cost control

## Files

```text
part-03-arc-runners/
  kubernetes/                   future ARC local manifests and Helm values
  terraform/                    future ARC EKS lab
  runner-images/                future custom runner images
```

## Practice Order

1. Read [the walkthrough](walkthrough.md).
2. Inventory the current GitHub runner setup before building anything.
3. Build a local ARC runner scale set lab with a test repo.
4. Create a custom runner image.
5. Smoke-test EKS with a hello app before installing ARC.
6. Move the lab to EKS after the local mechanics are clear.

## Runs-On Mapping

The runner scale set installation name maps to the workflow `runs-on` value:

```yaml
jobs:
  build:
    runs-on: arc-runner-set
```

GitHub queues the job for that runner, ARC creates an ephemeral runner pod, and that pod runs the job.

## EKS Smoke Test

```bash
aws sts get-caller-identity
aws eks update-kubeconfig --name <cluster> --region <region>
kubectl get nodes
kubectl get pods -A
kubectl auth can-i get pods -A
kubectl apply -f part-01-local-kubernetes/manifests/hello-k8s.yaml
kubectl get all -n hello
```

## Debugging Checklist

```bash
kubectl get pods -A
kubectl get events -A --sort-by=.metadata.creationTimestamp
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace>
kubectl exec -it <pod> -n <namespace> -- sh
kubectl get svc -A
kubectl get ingress -A
kubectl get pvc -A
```

## Apple Silicon Checks

```bash
uname -m
docker buildx ls
kubectl get nodes -o wide
```

Runner images and downloaded binaries should support `linux/arm64` when they run locally on the MacBook Air M2 path.

## EKS Cost Note

Start with managed node groups. Avoid Karpenter, EKS Auto Mode, advanced autoscaling, and NAT Gateway until the basic runner scale set flow works. Watch EKS control plane charges, EC2 node time, EBS storage, public IPv4 addresses, and any load balancers.

## What I Should Be Able To Explain

- What pod runs the GitHub job
- How GitHub finds the runner
- What the runner scale set does
- Where secrets live
- Why a runner pod failed to start
- How EKS node capacity affects job startup time

## So What?

ARC teaches CI as a platform problem. Instead of maintaining long-lived runner machines, you learn to run jobs on short-lived pods with explicit images, labels, isolation boundaries, and scaling rules.
