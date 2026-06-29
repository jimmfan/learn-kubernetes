# Local Kubernetes Walkthrough

This lab builds basic `kubectl` muscle memory against Docker Desktop Kubernetes.

The goal is momentum. Run the fast path first, then come back for the optional practice. You do not need to understand every Kubernetes concept before moving on. You need to know how to create an app, inspect what Kubernetes created, expose it, test it, and clean it up.

## How To Use This Lab

Do this first:

1. Verify the cluster.
2. Create the `lab` namespace.
3. Create the `hello` Deployment.
4. Scale it.
5. Expose it with a Service.
6. Port-forward and open it in your browser.
7. Inspect the objects Kubernetes created.
8. Clean up.

Then, if you have energy, do the optional practice:

- Delete a Pod and watch Kubernetes replace it.
- Break and fix a Service selector.
- Roll out and roll back an image change.
- Apply the YAML version.
- Rebuild the same app shape with Terraform.

Names used here:

| Name | What It Is | Where It Lives |
|------|------------|----------------|
| `lab` | Namespace | Created by this walkthrough |
| `hello` | Deployment and Service | Created by this walkthrough inside `lab` |
| `hello` | Namespace | Created later by `hello-k8s.yaml` |
| `hello-web` | Deployment and Service | Created later by YAML and Terraform examples |
| `tf-hello` | Namespace | Created later by Terraform |

Kubernetes names are scoped by resource type and namespace. A Deployment named `hello` in the `lab` namespace is separate from a Namespace named `hello`.

Most commands follow this shape:

```text
kubectl <verb> <resource-type> <resource-name> <flags>
```

Example:

```bash
kubectl get pods -n lab
```

Read that as: ask Kubernetes to list Pods in the `lab` namespace.

## Prerequisites

Before starting, make sure:

- Docker Desktop is running.
- Docker Desktop Kubernetes is enabled.
- `kubectl` is installed and available in your shell.
- No AWS account or AWS credentials are required for this local lab.

You can run these commands from either your Mac host or the devcontainer, as long as `kubectl` can reach Docker Desktop Kubernetes. In this repo, most tooling usually runs inside the Linux devcontainer while Docker Desktop Kubernetes runs through Docker Desktop on the Mac.

## What This Lab Creates

The fast path creates:

- one Namespace: `lab`
- one Deployment: `hello`
- one ReplicaSet managed by the Deployment
- one or more Pods managed by the ReplicaSet
- one ClusterIP Service: `hello`

The cleanup step deletes the `lab` namespace, which deletes the lab objects inside it. In local Docker Desktop Kubernetes, this does not create AWS resources or AWS cost.

## Optional Map

If you want the big picture before running commands, read:

[Kubernetes Universe Map](kubernetes-universe-map.md)

If you want to go fast, skip the map for now and come back after the lab. The commands below will still work.

## 1. Verify The Cluster

Before creating anything, make sure `kubectl` is pointed at Docker Desktop Kubernetes:

```bash
kubectl config current-context
kubectl get nodes
```

You are looking for:

- Current context: `docker-desktop`.
- At least one node with `STATUS` of `Ready`.

Why this matters:

- A context is the `kubectl` connection profile: cluster, credentials, and sometimes default namespace.
- Nodes are the machines where Pods run.
- If you are pointed at the wrong cluster, every later command goes to the wrong place.

If the context is wrong:

```bash
kubectl config get-contexts
kubectl config use-context docker-desktop
```

If no node is `Ready`, stop here and fix Docker Desktop Kubernetes before continuing.

Apple Silicon note: the nginx image used in this lab supports `linux/arm64`, so it should run normally on your M2 Mac through Docker Desktop Kubernetes.

## 2. Create A Namespace

Create a scratch area for this lab:

```bash
kubectl create namespace lab
kubectl get pods -n lab
```

You are looking for:

- `namespace/lab created`, or an `AlreadyExists` message if you created it earlier.
- No Pods yet in `lab`.

If you see an `AlreadyExists` message, that only means the namespace already exists. Continue with the next command.

Why this matters:

- A namespace groups related Kubernetes objects.
- The `-n lab` flag means "run this command in the `lab` namespace."
- Cleanup is easy because deleting the namespace deletes the lab objects inside it.

Keep using `-n lab` explicitly in this walkthrough. It is a little more typing, but it makes your shell history clear.

## 3. Find Your Place Later

If you come back later and forget where you stopped, run:

```bash
kubectl config current-context
kubectl get namespace lab
kubectl get all -n lab
```

Read it like this:

- If `lab` is not found, start at **Create A Namespace**.
- If `lab` exists but has no app resources, start at **Create The Deployment**.
- If `lab` already has resources, continue from the section that matches what you see.

This checkpoint intentionally avoids app-specific commands because the app may not exist yet.

If you started this walkthrough before the app name changed, your cluster may still have a Deployment named `nginx-demo`. That was the old name for the same lab app. Either substitute `nginx-demo` for `hello` in your current session, or delete the `lab` namespace and restart with the shorter `hello` name.

## 4. Create The Deployment

Create an nginx Deployment named `hello`:

```bash
kubectl create deployment hello --image=nginx:1.27-alpine -n lab
kubectl get all -n lab
kubectl get pods --show-labels -n lab
```

You are looking for:

- `deployment.apps/hello` with `1/1` ready.
- One Pod whose name starts with `hello-`.
- One ReplicaSet whose name starts with `hello-`.
- Pod labels including `app=hello`.

What you just created:

```text
Deployment -> ReplicaSet -> Pod -> Container
```

If you want to zoom in on just that chain, run:

```bash
kubectl get deploy,pods,rs -n lab
```

The Deployment is the desired state: "keep nginx running." Kubernetes creates a ReplicaSet, and the ReplicaSet creates the Pod. The Pod runs the nginx container.

Important concept:

- You usually create Deployments, not raw Pods.
- Pods are disposable.
- The Deployment and ReplicaSet are what bring Pods back when they disappear.

## 5. Scale The Deployment

Ask Kubernetes to run three copies:

```bash
kubectl scale deployment hello --replicas=3 -n lab
kubectl get deployment hello -n lab
kubectl get pods -o wide -n lab
```

You are looking for:

- Deployment readiness moving to `3/3`.
- Three Pods whose names start with `hello-`.
- `-o wide` showing extra details such as Pod IP and node.

Why this matters:

- You changed desired state from one replica to three.
- Kubernetes reconciled actual state by creating more Pods.
- In EKS, this same action also depends on having enough EC2 or Fargate capacity.

## 6. Expose A Service

Create a stable network endpoint for the Pods:

```bash
kubectl expose deployment hello --port=80 --type=ClusterIP -n lab
kubectl get svc -n lab
```

You are looking for:

- A Service named `hello`.
- `TYPE` of `ClusterIP`.
- `PORT(S)` including `80/TCP`.

Why this matters:

- Pods can be replaced and get new IPs.
- A Service gives clients one stable name and virtual IP.
- The Service finds Pods using labels.

Inspect the connection between Service and Pods:

```bash
kubectl describe svc hello -n lab
kubectl get endpointslices -n lab -l kubernetes.io/service-name=hello
kubectl get pods --show-labels -n lab
```

You are looking for:

- The Service selector matching the Pod label, usually `app=hello`.
- EndpointSlice addresses for the ready Pods behind the Service.

Simple model:

```text
Service -> selector/labels -> Pods
EndpointSlice -> current backend Pod IPs
```

EndpointSlices are the modern way Kubernetes tracks the backend Pod IPs for a Service. Older examples may use `kubectl get endpoints`; both are trying to answer which Pod IPs are behind a Service.

## 7. Access The App

Forward a local port to the Service:

```bash
kubectl port-forward svc/hello 8080:80 -n lab
```

Leave that command running. Open this in your browser:

```text
http://localhost:8080
```

You should see the nginx welcome page.

Stop port forwarding with `Ctrl+C` when you are done.

If port `8080` is already in use, choose another local port:

```bash
kubectl port-forward svc/hello 8081:80 -n lab
```

Then open:

```text
http://localhost:8081
```

Why this matters:

- `ClusterIP` Services are reachable inside the cluster, not directly from your browser.
- `port-forward` creates a temporary local tunnel for testing.
- In EKS, real external traffic usually uses a LoadBalancer or Ingress instead.

## 8. Inspect What You Built

Run one compact inventory:

```bash
kubectl get all -n lab
```

You should see:

- `pod/hello-...`
- `service/hello`
- `deployment.apps/hello`
- `replicaset.apps/hello-...`

`kubectl get all` is a quick first glance. It does not literally show every Kubernetes resource type, but it is enough for this lab.

## 9. Fast Path Success Criteria

You completed the fast path if you can:

- see three `hello` Pods
- see a `hello` ClusterIP Service
- open the nginx welcome page through `kubectl port-forward`
- explain that the Deployment owns the ReplicaSet, the ReplicaSet owns the Pods, and the Service finds Pods by labels
- clean everything up by deleting the `lab` namespace when you are done practicing

Do not worry if you cannot explain every detail yet. The point is to start connecting commands to the Kubernetes objects they create.

## 10. Clean Up The Fast Path

If you want to keep practicing, skip cleanup for now and continue to the optional sections. If you are done, delete the namespace:

```bash
kubectl delete namespace lab
```

Confirm cleanup:

```bash
kubectl get namespace lab
```

You may briefly see the namespace in `Terminating`. After deletion finishes, Kubernetes should report that `lab` was not found.

Cost note: in this local Docker Desktop lab, there is no AWS cost. In EKS, cleanup also matters because Kubernetes objects can create billable AWS resources such as load balancers or volumes.

## Optional Practice: Debugging Ladder

Use these when something does not look right:

```bash
kubectl get pods -n lab
kubectl describe deployment hello -n lab
kubectl describe pod <pod-name> -n lab
kubectl logs <pod-name> -n lab
kubectl get events -n lab --sort-by=.metadata.creationTimestamp
kubectl get svc,endpointslices -n lab
```

Use them in this order:

- `get pods`: what is running?
- `describe deployment`: what is Kubernetes trying to maintain?
- `describe pod`: did scheduling, image pull, or container startup fail?
- `logs`: what did the app process write?
- `events`: what happened recently?
- `get svc,endpointslices`: does traffic have a Service and ready backend Pods?

This is the debug habit to carry into Coder, ARC, and EKS.

## Optional Practice: Self-Healing

Make sure the `lab` namespace and `hello` Deployment still exist. Then delete one Pod:

```bash
kubectl get pods -n lab
kubectl delete pod <pod-name> -n lab
kubectl get pods -n lab
kubectl get deployment hello -n lab
```

Replace `<pod-name>` with a real Pod name from `kubectl get pods -n lab`.

You are looking for:

- The deleted Pod disappearing or moving to `Terminating`.
- A new Pod appearing with a different name.
- The Deployment returning to the desired replica count.

Why this matters:

- Pods are replaceable.
- The Deployment owns a ReplicaSet.
- The ReplicaSet creates replacement Pods when actual state falls below desired state.

## Optional Practice: Break And Fix The Service Selector

Make sure the `lab` namespace, `hello` Deployment, and `hello` Service still exist.

First, inspect the Service selector:

```bash
kubectl describe svc hello -n lab
kubectl get pods --show-labels -n lab
kubectl get endpointslices -n lab -l kubernetes.io/service-name=hello
```

The Service selector should match the Pod label, usually `app=hello`.

Now break the Service selector so it no longer matches the Pods:

```bash
kubectl patch svc hello -n lab -p '{"spec":{"selector":{"app":"does-not-match"}}}'
kubectl get endpointslices -n lab -l kubernetes.io/service-name=hello
```

You are looking for:

- The Service still exists.
- The Pods still exist.
- The Service has no ready backend Pod IPs.

Fix the selector:

```bash
kubectl patch svc hello -n lab -p '{"spec":{"selector":{"app":"hello"}}}'
kubectl get endpointslices -n lab -l kubernetes.io/service-name=hello
```

Why this matters:

- Services find Pods with selectors and labels.
- If labels and selectors do not match, traffic has nowhere to go.
- The quick debugging question is: "Service exists, but does it have endpoints?"

## Optional Practice: Roll Out And Roll Back

Change the nginx image version:

```bash
kubectl set image deployment/hello nginx=nginx:1.26-alpine -n lab
kubectl rollout status deployment hello -n lab
kubectl get pods -n lab
kubectl rollout history deployment hello -n lab
```

You are looking for:

- Kubernetes replacing old Pods with new Pods.
- Rollout status reporting success.
- Rollout history showing revisions.

Undo the change:

```bash
kubectl rollout undo deployment hello -n lab
kubectl rollout status deployment hello -n lab
kubectl rollout history deployment hello -n lab
```

Why this matters:

- Updating a Deployment changes its Pod template.
- Kubernetes rolls that change out by replacing Pods.
- Rollback returns to a previous revision.

This is the same basic mechanism behind application deploys in real clusters.

## Follow-Up: YAML App

This is a separate follow-up lab. It repeats the same app shape with a YAML file instead of one command at a time.

The YAML lab uses a separate namespace named `hello`. That namespace is different from the `hello` Deployment and Service created earlier in the `lab` namespace.

Apply the manifest:

```bash
kubectl apply -f part-01-local-kubernetes/manifests/hello-k8s.yaml
kubectl get all -n hello
kubectl get endpointslices -n hello -l kubernetes.io/service-name=hello-web
```

Inspect it:

```bash
kubectl describe deployment hello-web -n hello
kubectl get pods -n hello --show-labels
kubectl describe svc hello-web -n hello
```

Access it:

```bash
kubectl port-forward -n hello svc/hello-web 8080:80
```

Open:

```text
http://localhost:8080
```

If port `8080` is still being used by another port-forward command, stop the other command with `Ctrl+C` or use another local port:

```bash
kubectl port-forward -n hello svc/hello-web 8081:80
```

Clean up:

```bash
kubectl delete -f part-01-local-kubernetes/manifests/hello-k8s.yaml
```

What this teaches:

- `kubectl apply -f` sends desired state from a file to Kubernetes.
- YAML is repeatable and reviewable.
- The manifest adds resource requests and limits, which the one-line Deployment command skipped.
- If a resource is created from YAML, prefer updating it through YAML so the file remains the source of truth.

## Follow-Up: Terraform App

This is another follow-up lab. It recreates the same app shape through Terraform and the Kubernetes provider.

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

What this teaches:

- Kubernetes stores desired state in the cluster.
- Terraform stores its own state for resources it manages.
- `terraform plan` previews changes before applying them.
- Terraform should not silently take ownership of resources you created directly with `kubectl`.

The YAML lab uses the `hello` namespace. The Terraform lab defaults to `tf-hello` so the ownership boundary stays clear.

Try one controlled change:

```bash
terraform plan -var='replicas=3'
```

Read the plan before applying. You should be able to predict that Terraform wants the Deployment replica count to change from two to three.

Ownership note:

- Terraform state records what Terraform believes it owns.
- If you create something with `kubectl` and then create something similar with Terraform, those are not automatically the same resource.
- Keeping namespaces separate while learning makes ownership easier to see.

## Core Mental Model

Keep this small model in your head:

```text
kubectl -> Kubernetes API server -> desired state

Deployment -> ReplicaSet -> Pods -> Containers

Service -> selector/labels -> Pods

EndpointSlice -> current backend Pod IPs
```

When debugging, ask which layer you are inspecting:

- Context: which cluster am I changing?
- Namespace: where does this object live?
- Deployment: what desired app state did I declare?
- ReplicaSet: what Pod copies are being maintained?
- Pod: what is actually running?
- Service: how does traffic find the Pods?
- EndpointSlice: which Pod IPs are behind the Service?
- Events and logs: what happened when Kubernetes or the app tried to do the work?
- Terraform state: which resources does Terraform think it owns?

## Mapping To EKS

The Kubernetes objects stay mostly the same in EKS. The surrounding infrastructure changes.

| Local | EKS |
|------|-----|
| Docker Desktop cluster | EKS cluster |
| Local Docker Desktop node | EC2 nodes or Fargate capacity |
| ClusterIP Service | ClusterIP Service |
| EndpointSlice | EndpointSlice |
| `kubectl port-forward` | Load balancer or Ingress for real traffic |
| Local kubeconfig | AWS-generated kubeconfig |

Extra AWS concepts around EKS:

- VPC networking controls how the cluster, nodes, Pods, and load balancers communicate.
- IAM controls which AWS actions clusters, nodes, and Pods can perform.
- Security groups act like AWS network firewalls.
- Load balancers can expose Kubernetes Services outside the cluster.
- EBS volumes can provide persistent storage for Pods.
- CloudWatch can store logs and metrics.

So what? This local lab teaches the Kubernetes control loop without AWS cost. EKS adds cloud infrastructure around the same core behaviors.

## What I Should Be Able To Explain

After the fast path, aim to explain:

- Why you check the active context before changing anything.
- What a namespace does and why cleanup is easier with one.
- Deployment vs ReplicaSet vs Pod.
- Why Pods are replaceable.
- How a Service finds Pods through labels.
- How EndpointSlices show current Service backends.
- Why `port-forward` is useful for local testing.

After the optional sections, also aim to explain:

- How to debug a basic Pod problem with `describe`, events, and logs.
- Why a Service can exist but still have no working backends.
- What happens during rollout and rollback.
- Why YAML, Terraform, and imperative commands are different ownership styles.
- Why the same Kubernetes commands still matter when the cluster moves to EKS.
