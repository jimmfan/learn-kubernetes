# Part 02: Coder Platform

Plan: [Coder Platform Project Plan](../project-plans/coder-platform-project.md)

Goal: learn how Coder turns developer workspaces into a platform running on Docker, Kubernetes, and eventually EKS.

## What This Part Teaches

- Coder control plane vs workspace compute
- Helm values and Kubernetes deployment settings
- Coder templates as Terraform
- Workspace agents, apps, parameters, and lifecycle
- EKS basics needed for Coder: VPC, nodes, load balancers, storage, IAM, and cost

## Files

```text
part-02-coder-platform/
  coder-templates/             future full workspace templates
  helm-values/
    values-local.yaml           Coder Helm values for local Kubernetes
    values-eks.yaml             Coder Helm values starter for EKS
  eks/
    eksctl-auto-mode.yaml       EKS Auto Mode starter
  kubernetes/                   local Coder Kubernetes notes and manifests
  terraform/
    coder-template-kubernetes/  Coder workspace template practice
    eks-starter/                small EKS cluster with managed nodes
```

## Practice Order

1. Read [the project plan](../project-plans/coder-platform-project.md).
2. Install Coder locally with Helm using `helm-values/values-local.yaml`.
3. Push and study the Kubernetes workspace template.
4. Study the EKS starter before creating AWS resources.
5. Deploy Coder on EKS only when you are ready for AWS cost.

## AWS Cost Note

The local Coder path should cost `$0`. The EKS path creates billable AWS resources: the EKS control plane, EC2 worker nodes, EBS volumes, NAT gateway, public IPv4 addresses, and any load balancers. Treat EKS labs as short-lived unless you intentionally want them running.

## So What?

Coder is a good bridge from Kubernetes basics into platform engineering. You learn how a platform team packages compute, storage, networking, identity, and developer experience into a self-service workflow.
