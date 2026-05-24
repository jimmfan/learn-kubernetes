# Local Kubernetes Walkthrough

This walkthrough builds basic `kubectl` muscle memory against the local Docker Desktop Kubernetes cluster.

## Verify The Cluster

```bash
kubectl config get-contexts
kubectl get nodes
```

You should see the `docker-desktop` node.

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
