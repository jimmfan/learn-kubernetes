# Part 03: ARC Runners

Plan: [ARC On Kubernetes Project Plan](../project-plans/arc-on-kubernetes-project.md)

Goal: learn how GitHub Actions Runner Controller runs CI jobs as ephemeral Kubernetes workloads, then map that model to EKS.

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

1. Read [the project plan](../project-plans/arc-on-kubernetes-project.md).
2. Inventory the current GitHub runner setup before building anything.
3. Build a local ARC lab with a test repo.
4. Create a custom runner image.
5. Move the lab to EKS after the local mechanics are clear.

## So What?

ARC teaches CI as a platform problem. Instead of maintaining long-lived runner machines, you learn to run jobs on short-lived pods with explicit images, labels, isolation boundaries, and scaling rules.
