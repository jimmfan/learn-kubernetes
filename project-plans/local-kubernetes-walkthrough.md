# Local Kubernetes Walkthrough

This walkthrough builds basic `kubectl` muscle memory against the local Docker Desktop Kubernetes cluster.

This is Part 1 of the 4-week ramp-up. Keep it focused on the Kubernetes behaviors needed later for Coder, EKS, and ARC.

## Verify The Cluster

```bash
kubectl config get-contexts
kubectl get nodes
```

You should see the `docker-desktop` node.

## Apple Silicon Checks

Run these once when the devcontainer starts:

```bash
uname -m
docker buildx ls
kubectl get nodes -o wide
```

On a MacBook Air M2, expect `arm64` or `aarch64` somewhere in the chain. For this repo, downloaded CLIs and Docker images should support `linux/arm64` when they run inside the devcontainer or cluster.

## Create A Namespace

```bash
kubectl create namespace lab
kubectl config set-context --current --namespace=lab
```

A namespace is a logical workspace inside the cluster.

## Deploy Nginx

```bash
kubectl create deployment nginx-demo --image=nginx:1.27
kubectl get pods
```

This creates:

```text
Deployment -> ReplicaSet -> Pods -> Containers
```

The Deployment declares the desired state and Kubernetes reconciles the cluster to match it.

## Scale The Deployment

```bash
kubectl scale deployment nginx-demo --replicas=3
kubectl get pods
```

Kubernetes creates additional Pods to match the desired replica count.

## Expose A Service

```bash
kubectl expose deployment nginx-demo --port=80 --type=ClusterIP
kubectl get svc
```

A Service gives Pods a stable network endpoint and load balances traffic across matching Pods.

## Access The App

```bash
kubectl port-forward svc/nginx-demo 8080:80
```

Open:

```text
http://localhost:8080
```

This creates a temporary tunnel:

```text
localhost:8080
  -> Kubernetes Service
    -> Pods
```

## View Resources

```bash
kubectl get all
```

Shows common resources:

- Pods
- Services
- Deployments
- ReplicaSets

## Debugging Checklist

Use this same checklist in every track before guessing:

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

## Describe A Deployment

```bash
kubectl describe deployment nginx-demo
```

Useful for:

- labels
- selectors
- rollout status
- events
- replica counts

## Describe A Pod

```bash
kubectl get pods
kubectl describe pod <pod-name>
```

Useful for:

- scheduling issues
- image pull failures
- events
- container status
- node placement

## View Logs

```bash
kubectl logs <pod-name>
```

For multi-container Pods:

```bash
kubectl logs <pod-name> -c <container-name>
```

## Test Self-Healing

Delete a Pod:

```bash
kubectl delete pod <pod-name>
kubectl get pods
```

Kubernetes recreates the Pod because the Deployment still wants the desired replica count.

## Roll Out A Change

```bash
kubectl set image deployment/nginx-demo nginx=nginx:1.26
kubectl rollout status deployment nginx-demo
```

Kubernetes gradually replaces old Pods with new Pods.

## Roll Back

```bash
kubectl rollout undo deployment nginx-demo
```

This reverts the Deployment to the previous version.

## Clean Up

```bash
kubectl delete namespace lab
```

That deletes all resources inside the namespace.

## Core Mental Model

```text
Deployment -> ReplicaSet -> Pods -> Containers

Service -> routes traffic to Pods
```

## Mapping To EKS

| Local | EKS |
|------|------|
| docker-desktop | EKS cluster |
| local node | EC2 / Fargate |
| ClusterIP | ClusterIP |
| port-forward | ALB / LoadBalancer |
| kubeconfig | AWS CLI kubeconfig |

The Kubernetes resources remain mostly the same.

The main differences in EKS are surrounding AWS infrastructure:

- VPC
- IAM
- Security groups
- Load balancers
- EBS
- CloudWatch
- Terraform

## Recommended Next Topics

- ConfigMaps and Secrets
- Resource requests and limits
- Readiness and liveness probes
- Ingress
- Helm
- EKS with Terraform
- AWS Load Balancer Controller
- IRSA / EKS Pod Identity
- EBS CSI driver
- Cluster logging and monitoring

## What I Should Be Able To Explain

- Deployment vs ReplicaSet vs Pod
- Service vs port-forward
- Labels and selectors
- Namespace isolation
- How to debug a failing pod using events, `describe`, and logs
