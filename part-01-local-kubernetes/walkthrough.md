# Local Kubernetes Walkthrough

This walkthrough builds basic `kubectl` muscle memory against the local Docker Desktop Kubernetes cluster.

This is Part 1 of the 4-week ramp-up. Keep it focused on the Kubernetes behaviors needed later for Coder, EKS, and ARC.

The point is not to memorize commands. The point is to learn what question each command answers:

- Am I talking to the right cluster?
- Does the cluster have a node that can run Pods?
- What did I ask Kubernetes to run?
- What did Kubernetes create on my behalf?
- How does traffic reach the app?
- Where do I look when something is broken?

## Kubernetes Universe Map

Before starting the hands-on commands, read the concept map:

[Kubernetes Universe Map](kubernetes-universe-map.md)

That page gives you the big picture. This walkthrough turns the map into commands you can run.

## Verify The Cluster

Before creating anything, verify that `kubectl` is aimed at the cluster you intend to use.

```bash
kubectl config get-contexts
kubectl get nodes
```

Why you are running this:

- `kubectl` can talk to many clusters: Docker Desktop, EKS, kind, minikube, and others.
- The active context decides where your commands go.
- Running commands against the wrong cluster is one of the easiest mistakes to make.
- Nodes are the machines where Pods actually run. If the cluster has no usable nodes, your app cannot start.

`kubectl config get-contexts` lists the saved Kubernetes connection profiles in your kubeconfig. A context combines a cluster, user credentials, and usually a default namespace. The `*` marks the active context, which is where future `kubectl` commands will run.

Your kubeconfig file is the local config file that tells `kubectl` how to connect to Kubernetes clusters. It usually lives at `~/.kube/config` and contains cluster API server addresses, user credentials, and contexts. In this repo, the devcontainer copies your Mac's kubeconfig and adjusts the Docker Desktop Kubernetes endpoint so commands from inside the container can still reach the local cluster.

`kubectl get nodes` asks the active cluster which worker machines are available to run Pods. In Docker Desktop Kubernetes, this is usually one local node. In EKS, nodes are usually EC2 instances or Fargate capacity.

What to look for:

- The active context should be `docker-desktop`.
- You should see a node named `docker-desktop`.
- The node status should be `Ready`.

If the node is not `Ready`, do not continue yet. Kubernetes can accept Deployment objects, but it will not be able to schedule healthy Pods onto a broken or missing node.

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

Why these are useful:

- `current-context` answers "what cluster am I about to change?"
- `get-contexts -o name` gives a clean list of context names.
- `use-context docker-desktop` switches `kubectl` back to Docker Desktop Kubernetes.
- `view` shows the full kubeconfig that `kubectl` is using.
- `view --minify` shows only the kubeconfig details for the active context.
- `get nodes -o wide` adds useful node details such as IPs, OS, container runtime, and architecture.
- `describe node docker-desktop` shows capacity, labels, taints, conditions, and recent node events.
- `get namespaces` shows the logical workspaces in the cluster.
- `get pods --all-namespaces` shows what is already running before you add your own app.

So what? In EKS, this same habit prevents expensive or risky mistakes. You will often have separate dev, staging, and production clusters. Always confirm the target before changing infrastructure.

## Apple Silicon Checks

Run these once when the devcontainer starts:

```bash
uname -m
docker buildx ls
kubectl get nodes -o wide
```

Why you are running this:

- Your MacBook Air M2 is ARM-based.
- The devcontainer also usually runs as Linux ARM.
- Kubernetes nodes have a CPU architecture too.
- Container images and downloaded CLI binaries need to match the architecture where they run.

What to look for:

- `uname -m` should show `aarch64` or `arm64` inside the devcontainer.
- `docker buildx ls` should show builders that can build for ARM.
- `kubectl get nodes -o wide` should show node architecture and container runtime details.

On a MacBook Air M2, expect `arm64` or `aarch64` somewhere in the chain. For this repo, downloaded CLIs and Docker images should support `linux/arm64` when they run inside the devcontainer or cluster.

So what? This matters later for EKS node groups. If you choose AWS Graviton instances for lower cost, every workload scheduled there needs a `linux/arm64` compatible image.

## Create A Namespace

Create a separate workspace for the lab:

```bash
kubectl create namespace lab
kubectl config set-context --current --namespace=lab
```

Why you are running this:

- A namespace keeps this walkthrough's resources separate from Kubernetes system resources.
- Setting the current namespace lets you type shorter commands.
- Cleanup becomes easy because deleting the namespace deletes everything inside it.

`kubectl create namespace lab` creates a logical workspace named `lab`.

`kubectl config set-context --current --namespace=lab` changes your active context so future namespaced commands default to `lab`. Without this, you would need to add `-n lab` to most commands.

Check your default namespace:

```bash
kubectl config view --minify
kubectl get pods
```

What to look for:

- The minified kubeconfig should show `namespace: lab`.
- `kubectl get pods` should return no resources yet, because the namespace is empty.

So what? Namespaces are everywhere in real clusters. Coder, ARC, ingress controllers, monitoring tools, and application teams usually live in separate namespaces so their resources are easier to manage and reason about.

## Deploy Nginx

Create a Deployment:

```bash
kubectl create deployment nginx-demo --image=nginx:1.27
kubectl get pods
```

Why you are running this:

- You are asking Kubernetes to run an app container.
- You are using a Deployment instead of a raw Pod because Deployments support replica management, rollouts, and rollback.
- `kubectl get pods` checks what Kubernetes created after you declared the desired state.

This creates:

```text
Deployment -> ReplicaSet -> Pod -> Container
```

The Deployment is your desired state: "run nginx from the `nginx:1.27` image." Kubernetes then creates a ReplicaSet, and the ReplicaSet creates a Pod. The Pod runs the nginx container.

Inspect the relationship:

```bash
kubectl get deployment
kubectl get replicaset
kubectl get pods
kubectl get pods --show-labels
```

What to look for:

- The Deployment should show `1/1` ready.
- The ReplicaSet name should start with `nginx-demo`.
- The Pod name should also start with `nginx-demo`.
- The Pod should have labels that let the Deployment and Service find it.

So what? Most platform tools you will run later, including Coder and ARC, ultimately create Pods. Learning to trace Deployment to ReplicaSet to Pod is how you understand what is actually running.

## Scale The Deployment

Ask Kubernetes to run three copies of nginx:

```bash
kubectl scale deployment nginx-demo --replicas=3
kubectl get pods
```

Why you are running this:

- You are changing desired state from one replica to three.
- You are watching Kubernetes reconcile the actual cluster to match that desired state.
- This demonstrates the controller loop: Kubernetes notices the gap and creates more Pods.

Check the Deployment again:

```bash
kubectl get deployment nginx-demo
kubectl get pods -o wide
```

What to look for:

- The Deployment should move toward `3/3` ready.
- You should see three nginx Pods.
- `-o wide` shows which node each Pod landed on. In Docker Desktop, they will usually all be on the same local node.

So what? In EKS, scaling a Deployment creates more Pods, but the cluster also needs enough EC2 or Fargate capacity to run them. Pod scaling and node capacity are related but separate layers.

## Expose A Service

Create a stable network endpoint for the Pods:

```bash
kubectl expose deployment nginx-demo --port=80 --type=ClusterIP
kubectl get svc
```

Why you are running this:

- Pods are temporary. They can be replaced during scaling, rollout, rollback, or self-healing.
- A Service gives the app a stable name and virtual IP inside the cluster.
- The Service load balances traffic across Pods selected by labels.

`ClusterIP` means the Service is reachable inside the cluster. It does not create an external load balancer.

Inspect how the Service finds Pods:

```bash
kubectl describe svc nginx-demo
kubectl get endpoints nginx-demo
kubectl get pods --show-labels
```

What to look for:

- The Service selector should match the nginx Pod labels.
- The endpoint list should contain the Pod IPs behind the Service.
- If the selector does not match any Pods, the Service exists but sends traffic nowhere.

So what? Services are the bridge between changing Pods and stable networking. In EKS, an internal `ClusterIP` Service still works the same way, while external access usually adds an AWS load balancer or ingress controller in front of it.

## Access The App

Forward a local port to the Service:

```bash
kubectl port-forward svc/nginx-demo 8080:80
```

Open:

```text
http://localhost:8080
```

Why you are running this:

- `ClusterIP` Services are not directly reachable from your laptop browser.
- `port-forward` creates a temporary debug tunnel from your machine to the Service.
- This lets you test the app without creating a public endpoint.

This creates a temporary path:

```text
localhost:8080
  -> Kubernetes Service nginx-demo:80
    -> one of the nginx Pods
```

Keep the `port-forward` command running while you test. Stop it with `Ctrl+C` when you are done.

So what? `port-forward` is a local debugging tool. In EKS, production traffic usually reaches apps through an AWS Application Load Balancer, Network Load Balancer, or ingress controller, not through `port-forward`.

## View Resources

List the common objects in the namespace:

```bash
kubectl get all
```

Why you are running this:

- You want a quick inventory of what the lab created.
- You can see the relationship between Service, Deployment, ReplicaSet, and Pods in one view.
- It is a fast sanity check before deeper debugging.

`kubectl get all` shows common resources:

- Pods
- Services
- Deployments
- ReplicaSets

It does not literally show every Kubernetes resource type. For example, ConfigMaps, Secrets, Ingresses, and PVCs are not included in this shortcut.

So what? `get all` is a quick first glance, not a complete audit. In real clusters, you will often follow it with more specific commands.

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

Why these commands are grouped together:

- `get pods -A` answers "what is running, and where?"
- `get events -A --sort-by=.lastTimestamp` answers "what recently happened in the cluster?"
- `describe pod` answers "what does Kubernetes know about this Pod's scheduling, image pulls, restarts, and events?"
- `logs` answers "what did the application process write to stdout or stderr?"
- `exec` answers "what can I inspect from inside the running container?"
- `get svc -A` answers "what stable network endpoints exist?"
- `get ingress -A` answers "what HTTP routes from outside the cluster exist?"
- `get pvc -A` answers "what storage claims exist?"

So what? This checklist separates Kubernetes problems from application problems. For example, an image pull error is different from nginx starting successfully but returning the wrong content.

## Describe A Deployment

Inspect the Deployment controller's view of the world:

```bash
kubectl describe deployment nginx-demo
```

Why you are running this:

- You want to know what the Deployment is trying to do.
- You want to see its selector, labels, rollout status, replica counts, and events.
- This is the best next command when Pods are missing, stuck, or not updating.

Useful sections:

- `Selector` shows which Pods belong to the Deployment.
- `Replicas` shows desired, updated, total, available, and unavailable counts.
- `Pod Template` shows the container image and labels new Pods should use.
- `Events` shows recent controller actions.

So what? Deployments are reconciliation objects. If reality does not match what you wanted, `describe deployment` helps you see what Kubernetes is trying to reconcile.

## Describe A Pod

Pick one Pod and inspect it:

```bash
kubectl get pods
kubectl describe pod <pod-name>
```

Why you are running this:

- A Pod is where the app container actually runs.
- `describe pod` shows whether the Pod was scheduled, whether the image pulled, whether containers started, and what recent events happened.
- This is usually the most useful command for startup failures.

Useful sections:

- `Node` shows where the Pod was scheduled.
- `Labels` show how controllers and Services find the Pod.
- `Containers` shows image, ports, state, readiness, restarts, and resource settings.
- `Conditions` show whether the Pod is scheduled, initialized, ready, and able to serve traffic.
- `Events` show scheduling, image pull, container start, and failure messages.

So what? In EKS, many failures show up here first: bad image names, missing IAM permissions, insufficient CPU or memory, failed volume mounts, or node scheduling problems.

## View Logs

Read the application logs:

```bash
kubectl logs <pod-name>
```

For multi-container Pods:

```bash
kubectl logs <pod-name> -c <container-name>
```

Why you are running this:

- Kubernetes can tell you whether the container started.
- Application logs tell you what the process did after it started.
- This is how you move from "Kubernetes problem" to "application problem."

For nginx, the logs are not exciting until traffic reaches it. Try loading `http://localhost:8080` while `port-forward` is running, then run `kubectl logs` again.

So what? ARC runners, Coder workspace agents, ingress controllers, and app workloads all rely heavily on logs. `describe` explains platform state; `logs` explains process behavior.

## Test Self-Healing

Delete one Pod:

```bash
kubectl get pods
kubectl delete pod <pod-name>
kubectl get pods
```

Why you are running this:

- You are proving that Pods managed by a Deployment are replaceable.
- You are watching Kubernetes restore the desired replica count.
- This is the core self-healing behavior Kubernetes is known for.

What to look for:

- The deleted Pod disappears or moves into `Terminating`.
- A new Pod appears with a different name.
- The Deployment returns to the desired number of ready replicas.

The Pod comes back because the Deployment still wants three replicas. More precisely, the Deployment owns a ReplicaSet, and the ReplicaSet creates a replacement Pod.

So what? You should usually treat Pods as disposable. Store important state outside the Pod, use Services for stable networking, and let controllers replace broken instances.

## Roll Out A Change

Change the nginx image version:

```bash
kubectl set image deployment/nginx-demo nginx=nginx:1.26
kubectl rollout status deployment nginx-demo
```

Why you are running this:

- You are changing the Deployment's Pod template.
- Kubernetes responds by gradually replacing old Pods with new Pods.
- `rollout status` waits and tells you whether the update completes.

Watch the rollout:

```bash
kubectl get pods
kubectl describe deployment nginx-demo
kubectl rollout history deployment nginx-demo
```

What to look for:

- New Pods are created with the new image.
- Old Pods are terminated after replacements become available.
- Rollout history records Deployment revisions.

So what? This is the same basic mechanism used for application deploys in real clusters. Later, Helm, Terraform, GitHub Actions, and GitOps tools may trigger the change, but the Kubernetes rollout behavior is the same.

## Roll Back

Undo the previous rollout:

```bash
kubectl rollout undo deployment nginx-demo
kubectl rollout status deployment nginx-demo
```

Why you are running this:

- You are practicing how to recover from a bad Deployment update.
- Kubernetes can return to the previous ReplicaSet revision.
- This gives you a quick operational escape hatch during labs.

Check the result:

```bash
kubectl rollout history deployment nginx-demo
kubectl describe deployment nginx-demo
```

So what? Rollback is helpful, but it is not a replacement for good release practices. In production, you also care about database migrations, config changes, external dependencies, and observability.

## Clean Up

Delete the namespace:

```bash
kubectl delete namespace lab
```

Why you are running this:

- The namespace contains all the lab resources.
- Deleting it removes the Deployment, ReplicaSet, Pods, and Service together.
- Cleanup keeps later labs from being confusing.

Confirm cleanup:

```bash
kubectl get namespace lab
kubectl get pods -n lab
```

What to expect:

- The namespace may briefly show as `Terminating`.
- After deletion completes, commands against `lab` should report that the namespace was not found.

So what? In AWS, cleanup also controls cost. Namespaces alone do not delete EKS clusters, EC2 nodes, load balancers, or EBS volumes unless those resources are managed as part of the deleted Kubernetes objects. Always understand what layer owns the billable resource.

## Core Mental Model

```text
Deployment -> ReplicaSet -> Pods -> Containers

Service -> routes traffic to Pods selected by labels

kubectl -> Kubernetes API server -> desired state -> controllers -> actual running Pods
```

The important habit is to ask which layer you are inspecting:

- Context and kubeconfig: which cluster am I changing?
- Node: where can Pods run?
- Namespace: where does this object live?
- Deployment: what desired app state did I declare?
- ReplicaSet: what Pod copies are being maintained?
- Pod: what is actually running?
- Service: how does traffic find the Pods?
- Events and logs: what happened when Kubernetes or the app tried to do the work?

## Mapping To EKS

| Local | EKS |
|------|------|
| docker-desktop | EKS cluster |
| local node | EC2 / Fargate |
| ClusterIP | ClusterIP |
| port-forward | ALB / LoadBalancer / Ingress for real traffic |
| kubeconfig | AWS CLI generated kubeconfig |

The Kubernetes resources remain mostly the same.

The main differences in EKS are surrounding AWS infrastructure:

- VPC networking decides how the cluster, nodes, Pods, and load balancers communicate.
- IAM decides what AWS actions the cluster, nodes, and Pods are allowed to perform.
- Security groups act like network firewalls around AWS resources.
- Load balancers expose Services to traffic outside the cluster.
- EBS volumes provide persistent block storage for Pods.
- CloudWatch stores logs and metrics when configured.
- Terraform can create both the AWS infrastructure and Kubernetes resources.

So what? This local lab teaches the Kubernetes control loop without AWS cost. EKS adds cloud infrastructure around the same core behaviors.

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

- Why you check the active context before changing anything
- What a namespace does and why cleanup is easier with one
- Deployment vs ReplicaSet vs Pod
- Why Pods are replaceable
- How Services find Pods through labels
- Service vs port-forward
- How to debug a failing Pod using events, `describe`, and logs
- Why the same Kubernetes commands still matter when the cluster moves to EKS
