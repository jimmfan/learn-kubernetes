# Local Kubernetes Walkthrough

This walkthrough builds basic `kubectl` muscle memory against the local Docker Desktop Kubernetes cluster.

This is Part 1 of the 4-week ramp-up. Keep it focused on the Kubernetes behaviors needed later for Coder, EKS, and ARC.

## Kubernetes Universe Map

Before starting the hands-on commands, read the concept map:

[Kubernetes Universe Map](kubernetes-universe-map.md)

## Verify The Cluster

Start by checking which Kubernetes cluster `kubectl` is pointed at and whether that cluster has a usable node.

```bash
kubectl config get-contexts
kubectl get nodes
```

`kubectl config get-contexts` lists the saved Kubernetes connection profiles in your kubeconfig. A context combines a cluster, user credentials, and usually a default namespace. The `*` marks the active context, which is where future `kubectl` commands will run.

Your kubeconfig file is the local config file that tells `kubectl` how to connect to Kubernetes clusters. It usually lives at `~/.kube/config` and contains cluster API server addresses, user credentials, and contexts. In this repo, the devcontainer copies your Mac's kubeconfig and adjusts the Docker Desktop Kubernetes endpoint so commands from inside the container can still reach the local cluster.

`kubectl get nodes` asks the active cluster which machines are available to run Pods. In Docker Desktop Kubernetes, this is usually one local node. In EKS, nodes are usually EC2 instances or Fargate capacity.

You should see the `docker-desktop` node.

Useful related commands:

```bash
kubectl config current-context
kubectl config get-contexts -o name
kubectl config use-context docker-desktop
kubectl config view
kubectl config view --minify
kubectl get nodes -o wide
kubectl describe node docker-desktop
kubectl get namespaces
kubectl get pods --all-namespaces
```

What they are for:

- `current-context` prints only the active context.
- `get-contexts -o name` gives a clean list of context names.
- `use-context docker-desktop` switches `kubectl` to Docker Desktop Kubernetes.
- `view` prints the full kubeconfig that `kubectl` is using.
- `view --minify` shows only the kubeconfig details for the active context.
- `get nodes -o wide` adds useful node details such as IPs, OS, container runtime, and architecture.
- `describe node docker-desktop` shows detailed node capacity, labels, taints, conditions, and recent events.
- `get namespaces` lists the logical workspaces in the cluster.
- `get pods --all-namespaces` shows what is running across the whole cluster.

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
