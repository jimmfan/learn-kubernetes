# Part 01: Local Kubernetes

Goal: build Kubernetes muscle memory locally before spending money in AWS.

Use this folder as the Part 1 control panel:

- Concept map: [Kubernetes Universe Map](kubernetes-universe-map.md)
- Lab manual: [Local Kubernetes Walkthrough](walkthrough.md)
- YAML app: [manifests/hello-k8s.yaml](manifests/hello-k8s.yaml)
- Terraform app: [terraform/local-kubernetes](terraform/local-kubernetes)

## What This Part Teaches

- `kubectl` basics: `get`, `describe`, `logs`, `exec`, `events`
- Kubernetes objects: Namespace, Deployment, ReplicaSet, Pod, Service
- Labels, selectors, and EndpointSlices
- Resource requests and limits
- Port forwarding and local debugging
- Terraform against the Kubernetes API

## Names You Will See

Part 1 uses three small namespaces on purpose:

| Namespace | Created By | Purpose |
|-----------|------------|---------|
| `lab` | Walkthrough commands | Imperative `kubectl` practice with `hello`. |
| `hello` | `hello-k8s.yaml` | Declarative YAML practice with `hello-web`. |
| `tf-hello` | Terraform module | Same app shape managed through Terraform state. |

The walkthrough also creates a Deployment and Service named `hello` inside the `lab` namespace. That is separate from the `hello` namespace used by the YAML follow-up lab.

That separation keeps each pass easy to clean up and makes the ownership model visible. Kubernetes owns the live desired state in the cluster. Terraform also keeps its own state file for the resources it manages.

## Files

```text
part-01-local-kubernetes/
  README.md                     this orientation file
  kubernetes-universe-map.md    concept map for the object model
  walkthrough.md                command-by-command local lab
  manifests/
    hello-k8s.yaml              plain Kubernetes YAML app
  terraform/
    local-kubernetes/           same app shape managed with Terraform
```

## Practice Order

1. Verify Docker Desktop Kubernetes from inside the devcontainer:

   ```bash
   kubectl config current-context
   kubectl get nodes
   ```

   The context should be `docker-desktop`, and at least one node should be `Ready`.

2. Read [the universe map](kubernetes-universe-map.md).

3. Work through [the walkthrough](walkthrough.md). This creates and deletes the `lab` namespace.

4. Apply the YAML app:

   ```bash
   kubectl apply -f part-01-local-kubernetes/manifests/hello-k8s.yaml
   kubectl get all -n hello
   kubectl get endpointslices -n hello -l kubernetes.io/service-name=hello-web
   kubectl port-forward -n hello svc/hello-web 8080:80
   ```

   Stop port forwarding with `Ctrl+C`, then clean up:

   ```bash
   kubectl delete -f part-01-local-kubernetes/manifests/hello-k8s.yaml
   ```

5. Rebuild the same app shape with Terraform:

   ```bash
   cd part-01-local-kubernetes/terraform/local-kubernetes
   terraform init
   terraform fmt
   terraform validate
   terraform plan
   terraform apply
   terraform output port_forward_command
   terraform destroy
   ```

## Apple Silicon Checks

```bash
uname -m
docker buildx ls
kubectl get nodes -L kubernetes.io/arch -o wide
```

On the MacBook Air M2, make sure images and downloaded binaries support `linux/arm64` when they run in the devcontainer or on local Kubernetes nodes. The nginx images used in Part 1 are multi-architecture images, so they should work on Apple Silicon without extra settings.

## Debugging Checklist

```bash
kubectl get pods -A
kubectl get events -A --sort-by=.metadata.creationTimestamp
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace>
kubectl exec -it <pod> -n <namespace> -- sh
kubectl get svc -A
kubectl get endpointslices -A
kubectl get ingress -A
kubectl get pvc -A
```

## What I Should Be Able To Explain

- Deployment vs ReplicaSet vs Pod
- Labels and selectors
- Service vs EndpointSlice vs port-forward
- Namespace isolation
- How to debug a failing pod
- Why Terraform-managed Kubernetes resources use Terraform state

## So What?

This is the zero-cost foundation. EKS, Coder, and ARC all use the same Kubernetes API concepts: Pods get scheduled, Services find Pods through labels, controllers reconcile desired state, and events explain failures.
