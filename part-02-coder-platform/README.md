# Part 02: Coder Platform

Walkthrough: [Coder Platform Walkthrough](walkthrough.md)

Goal: learn how Coder turns developer workspaces into a platform running on Docker, Kubernetes, and eventually EKS.

## What This Part Teaches

- Coder control plane vs workspace compute
- Helm values and Kubernetes deployment settings
- Coder templates as Terraform
- Workspace agents, apps, parameters, and lifecycle
- EKS basics needed for Coder: VPC, nodes, load balancers, storage, IAM, and cost

## Mental Model

```text
Coder control plane/server
  -> manages templates
  -> templates are Terraform
  -> Terraform creates Kubernetes-backed workspace resources
  -> workspace pods run on the cluster
```

## Files

```text
part-02-coder-platform/
  coder-templates/             future full workspace templates
  helm-values/
    values-local.yaml           Coder Helm values for local Kubernetes
    values-eks.yaml             Coder Helm values starter for EKS
  eks/
    eksctl-auto-mode.yaml       optional later EKS Auto Mode starter
  kubernetes/                   local Coder Kubernetes notes and manifests
  terraform/
    coder-template-kubernetes/  Coder workspace template practice
    eks-starter/                small EKS cluster with managed nodes
```

## Practice Order

1. Read [the walkthrough](walkthrough.md).
2. Install Coder locally with Helm using `helm-values/values-local.yaml`.
3. Push and study the Kubernetes workspace template.
4. Study the managed-node-group EKS starter before creating AWS resources.
5. Smoke-test EKS with a hello app before installing Coder.
6. Deploy Coder on EKS only when you are ready for AWS cost.

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

Use Docker images and downloaded binaries that support `linux/arm64` where applicable.

## AWS Cost Note

The local Coder path should cost `$0`. The first EKS version should use managed node groups, avoid Karpenter and EKS Auto Mode until later, and avoid NAT Gateway unless needed. EKS control plane time, EC2 nodes, EBS volumes, NAT Gateway, public IPv4 addresses, and load balancers can all cost real money.

## What I Should Be Able To Explain

- What runs the Coder control plane
- What creates workspace pods
- How templates map to Terraform
- Where persistent workspace data lives
- How Kubernetes resources map to developer workspaces

## So What?

Coder is a good bridge from Kubernetes basics into platform engineering. You learn how a platform team packages compute, storage, networking, identity, and developer experience into a self-service workflow.
