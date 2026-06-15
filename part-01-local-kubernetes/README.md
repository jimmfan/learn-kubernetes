# Part 01: Local Kubernetes

Walkthrough: [Local Kubernetes Walkthrough](walkthrough.md)

Concept map: [Kubernetes Universe Map](kubernetes-universe-map.md)

Goal: build Kubernetes muscle memory locally before spending money in AWS.

## What This Part Teaches

- `kubectl` basics: `get`, `describe`, `logs`, `exec`, `events`
- Kubernetes objects: Namespace, Deployment, ReplicaSet, Pod, Service
- Labels and selectors
- Resource requests and limits
- Port forwarding and local debugging
- Terraform against the Kubernetes API

## Files

```text
part-01-local-kubernetes/
  manifests/
    hello-k8s.yaml              plain Kubernetes YAML app
  terraform/
    local-kubernetes/           same app managed with Terraform
```

## Practice Order

1. Work through [the walkthrough](walkthrough.md).
2. Apply the YAML app:

   ```bash
   kubectl apply -f part-01-local-kubernetes/manifests/hello-k8s.yaml
   kubectl get all -n hello
   kubectl port-forward -n hello svc/hello-web 8080:80
   ```

3. Rebuild the same app with Terraform:

   ```bash
   cd part-01-local-kubernetes/terraform/local-kubernetes
   terraform init
   terraform plan
   terraform apply
   ```

## Apple Silicon Checks

```bash
uname -m
docker buildx ls
kubectl get nodes -o wide
```

On the MacBook Air M2, make sure images and downloaded binaries support `linux/arm64` when they run in the devcontainer or cluster.

## Debugging Checklist

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

## What I Should Be Able To Explain

- Deployment vs ReplicaSet vs Pod
- Service vs port-forward
- Labels and selectors
- Namespace isolation
- How to debug a failing pod

## So What?

This is the zero-cost foundation. EKS, Coder, and ARC all use the same Kubernetes API concepts: pods get scheduled, services find pods through labels, controllers reconcile desired state, and events explain failures.
