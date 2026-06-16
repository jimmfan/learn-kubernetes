# Local Kubernetes Walkthrough

This walkthrough builds basic `kubectl` muscle memory against the local Docker Desktop Kubernetes cluster.

This is the hands-on lab for Part 1 of the learning path. Keep it focused on the Kubernetes behaviors needed later for Coder, EKS, and ARC: desired state, controllers, Pods, Services, labels, events, logs, and cleanup.

The point is not to memorize commands. The point is to learn what question each command answers:

- Am I talking to the right cluster?
- Does the cluster have a node that can run Pods?
- What did I ask Kubernetes to run?
- What did Kubernetes create on my behalf?
- How does traffic reach the app?
- Where do I look when something is broken?

You will see these names in Part 1:

| Name | Where It Appears | Why It Exists |
|------|------------------|---------------|
| `lab` | This walkthrough | A scratch namespace for imperative `kubectl` practice. |
| `nginx-demo` | This walkthrough | The Deployment and Service you create by hand. |
| `hello` | YAML follow-up lab | The namespace created by `hello-k8s.yaml`. |
| `hello-web` | YAML and Terraform follow-up labs | The reusable app example managed declaratively. |
| `tf-hello` | Terraform follow-up lab | The namespace Terraform creates by default. |

The first pass is intentionally command-driven. The second and third passes use files so you can compare `kubectl apply` with Terraform.

Most `kubectl` commands in this walkthrough follow this shape:

```text
kubectl <verb> <resource-type> <resource-name> <flags>
```

For example:

```bash
kubectl get pods -n lab
```

Read that as:

- `kubectl`: the CLI client that talks to the Kubernetes API server.
- `get`: the action, or verb. Here it means "list or show."
- `pods`: the Kubernetes resource type.
- `-n lab`: a flag. Here it means "use the `lab` namespace."

Common verbs in this walkthrough:

- `get`: list resources.
- `describe`: show detailed status, settings, and events for one resource.
- `create`: create a new resource.
- `delete`: delete a resource.
- `logs`: print container logs.
- `exec`: run a command inside a container.

Common flags in this walkthrough:

- `-n <namespace>` or `--namespace <namespace>`: choose the namespace.
- `-A` or `--all-namespaces`: search across all namespaces.
- `-o wide`: show extra output columns.
- `--show-labels`: include labels in the output.

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

Command breakdown:

- `kubectl config get-contexts`: show the Kubernetes contexts saved in your kubeconfig.
- `kubectl get nodes`: list the worker nodes in the active cluster.
- `config` means you are inspecting or changing `kubectl` connection settings.
- `get` means "list resources."
- `nodes` is the Kubernetes resource type you are listing.

Why you are running this:

- `kubectl` can talk to many clusters: Docker Desktop, EKS, kind, minikube, and others.
- The active context decides where your commands go.
- Running commands against the wrong cluster is one of the easiest mistakes to make.
- Nodes are the machines where Pods actually run. If the cluster has no usable nodes, your app cannot start.

`kubectl config get-contexts` lists the saved Kubernetes connection profiles in your kubeconfig. A context combines a cluster, user credentials, and usually a default namespace. The `*` marks the active context, which is where future `kubectl` commands will run.

Your kubeconfig file is the local config file that tells `kubectl` how to connect to Kubernetes clusters. It usually lives at `~/.kube/config` and contains cluster API server addresses, user credentials, and contexts. In this repo, the devcontainer copies your Mac's kubeconfig and adjusts the Docker Desktop Kubernetes endpoint so commands from inside the container can still reach the local cluster.

`kubectl get nodes` asks the active cluster which worker machines are available to run Pods. In Docker Desktop Kubernetes, this can be one local node or a small local multi-node cluster. In EKS, nodes are usually EC2 instances or Fargate capacity.

What to look for:

- The active context should be `docker-desktop`.
- At least one node should be `Ready`.
- The node name may be `docker-desktop` in a kubeadm single-node setup, but Docker Desktop 4.51+ can also create a kind-based multi-node cluster with different node names.

If the node is not `Ready`, do not continue yet. Kubernetes can accept Deployment objects, but it will not be able to schedule healthy Pods onto a broken or missing node.

Useful related commands:

```bash
kubectl config current-context
kubectl config get-contexts -o name
kubectl config use-context docker-desktop
kubectl config view
kubectl config view --minify
kubectl get nodes -L kubernetes.io/arch -o wide
kubectl describe node <node-name>
kubectl get namespaces
kubectl get pods --all-namespaces
```

Why these are useful:

- `current-context` answers "what cluster am I about to change?"
- `get-contexts -o name` gives a clean list of context names.
- `use-context docker-desktop` switches `kubectl` back to Docker Desktop Kubernetes.
- `view` shows the full kubeconfig that `kubectl` is using.
- `view --minify` shows only the kubeconfig details for the active context.
- `get nodes -L kubernetes.io/arch -o wide` adds useful node details and the CPU architecture label.
- `describe node <node-name>` shows capacity, labels, taints, conditions, and recent node events. Replace `<node-name>` with a real name from `kubectl get nodes`.
- `get namespaces` shows the logical workspaces in the cluster.
- `get pods --all-namespaces` shows what is already running before you add your own app.

So what? In EKS, this same habit prevents expensive or risky mistakes. You will often have separate dev, staging, and production clusters. Always confirm the target before changing infrastructure.

## Architecture Note

This lab uses an official nginx image, which supports common CPU architectures including `linux/arm64`. The tag is pinned for repeatable lab output, not because it is special. On your Apple Silicon Mac, there should be nothing extra to configure for this walkthrough.

The bigger architecture lesson belongs in the learning guide: [Apple Silicon, ARM, And Container Images](../guides/kubernetes-platform-learning-guide.md#apple-silicon-arm-and-container-images).

## Create A Namespace

Create a separate workspace for the lab:

```bash
kubectl create namespace lab
```

Command breakdown:

- `kubectl create namespace lab`: create a Namespace resource named `lab`.
- `create` means "make a new resource."
- `namespace` is the resource type.
- `lab` is the name you are giving that namespace.

Why you are running this:

- A namespace keeps this walkthrough's resources separate from Kubernetes system resources.
- Using `-n lab` makes every command show exactly which namespace it targets.
- Cleanup becomes easy because deleting the namespace deletes everything inside it.

`kubectl create namespace lab` creates a logical workspace named `lab`.

In this walkthrough, use `-n lab` explicitly even though it is a little more typing. That builds the habit you will use in real clusters where you may switch between namespaces such as `coder`, `arc-runners`, `monitoring`, and `kube-system`.

Optional convenience command:

```bash
kubectl config set-context --current --namespace=lab
```

Command breakdown:

- `config set-context`: edit a saved kubeconfig context.
- `--current`: edit the context you are currently using.
- `--namespace=lab`: set `lab` as the default namespace for that context.

That changes your active context so future namespaced commands default to `lab`. It is useful during focused work, but explicit `-n lab` commands are clearer in shell history and safer when you work across multiple namespaces.

Check the namespace:

```bash
kubectl get namespace lab
kubectl get pods -n lab
```

Command breakdown:

- `kubectl get namespace lab`: show the Namespace resource named `lab`.
- `kubectl get pods -n lab`: list Pods in the `lab` namespace.
- `pods` is the resource type.
- `-n lab` is short for `--namespace lab`.

What to look for:

- The `lab` namespace should exist.
- `kubectl get pods -n lab` should return no resources yet, because the namespace is empty.

If you ran the optional default namespace command, you can verify it with:

```bash
kubectl config view --minify
```

In that case, the minified kubeconfig should show `namespace: lab`.

So what? Namespaces are everywhere in real clusters. Coder, ARC, ingress controllers, monitoring tools, and application teams usually live in separate namespaces so their resources are easier to manage and reason about.

## Deploy Nginx

Create a Deployment:

```bash
kubectl create deployment nginx-demo --image=nginx:1.27-alpine -n lab
kubectl get pods -n lab
```

Command breakdown:

- `kubectl create deployment nginx-demo`: create a Deployment named `nginx-demo`.
- `--image=nginx:1.27-alpine`: tell the Deployment to run containers from the `nginx:1.27-alpine` image.
- `-n lab`: create the Deployment in the `lab` namespace.
- `kubectl get pods -n lab`: list the Pods that now exist in `lab`.

Why you are running this:

- You are asking Kubernetes to run an app container.
- You are using a Deployment instead of creating a Pod directly because Deployments support replica management, rollouts, and rollback.
- `kubectl get pods -n lab` checks what Kubernetes created after you declared the desired state in the `lab` namespace.

A raw Pod means a Pod object you create directly, without a Deployment managing it. Kubernetes can run raw Pods, but they are not the usual choice for application workloads. If a raw Pod is deleted, Kubernetes does not automatically create a replacement. A Deployment gives Kubernetes a higher-level desired state: "keep this app running with this many replicas, using this container image."

This creates:

```text
Deployment -> ReplicaSet -> Pod -> Container
```

The Deployment is your desired state: "run nginx from the `nginx:1.27-alpine` image." Kubernetes then creates a ReplicaSet, and the ReplicaSet creates a Pod. The Pod runs the nginx container.

Inspect the relationship:

```bash
kubectl get deployment -n lab
kubectl get replicaset -n lab
kubectl get pods -n lab
kubectl get pods --show-labels -n lab
```

Command breakdown:

- `get deployment`: list Deployments.
- `get replicaset`: list ReplicaSets.
- `get pods`: list Pods.
- `--show-labels`: add a `LABELS` column so you can see the labels attached to each Pod.
- `-n lab`: read these resources from the `lab` namespace.

What to look for:

- The Deployment should show `1/1` ready.
- The ReplicaSet name should start with `nginx-demo`.
- The Pod name should also start with `nginx-demo`.
- The Pod should have labels that let the Deployment and Service find it.

So what? Most platform tools you will run later, including Coder and ARC, ultimately create Pods. Learning to trace Deployment to ReplicaSet to Pod is how you understand what is actually running.

## Scale The Deployment

Ask Kubernetes to run three copies of nginx:

```bash
kubectl scale deployment nginx-demo --replicas=3 -n lab
kubectl get pods -n lab
```

Command breakdown:

- `scale`: change the desired replica count for a scalable resource.
- `deployment nginx-demo`: target the Deployment named `nginx-demo`.
- `--replicas=3`: ask Kubernetes to keep three matching Pods running.
- `-n lab`: change the Deployment in the `lab` namespace.

Why you are running this:

- You are changing desired state from one replica to three.
- You are watching Kubernetes reconcile the actual cluster to match that desired state.
- This demonstrates the controller loop: Kubernetes notices the gap and creates more Pods.

Check the Deployment again:

```bash
kubectl get deployment nginx-demo -n lab
kubectl get pods -o wide -n lab
```

Command breakdown:

- `kubectl get deployment nginx-demo -n lab`: show only the `nginx-demo` Deployment in `lab`.
- `kubectl get pods -o wide -n lab`: list Pods with extra columns.
- `-o wide` means "use the wide output format," which often includes node name, Pod IP, and other useful details.

What to look for:

- The Deployment should move toward `3/3` ready.
- You should see three nginx Pods.
- `-o wide` shows which node each Pod landed on. In Docker Desktop, they will usually all be on the same local node.

So what? In EKS, scaling a Deployment creates more Pods, but the cluster also needs enough EC2 or Fargate capacity to run them. Pod scaling and node capacity are related but separate layers.

## Expose A Service

Create a stable network endpoint for the Pods:

```bash
kubectl expose deployment nginx-demo --port=80 --type=ClusterIP -n lab
kubectl get svc -n lab
```

Command breakdown:

- `expose deployment nginx-demo`: create a Service in front of the `nginx-demo` Deployment.
- `--port=80`: make the Service listen on port 80.
- `--type=ClusterIP`: make the Service reachable only inside the cluster.
- `svc` is the short name for `service`.
- `-n lab`: create and list the Service in the `lab` namespace.

Why you are running this:

- Pods are temporary. They can be replaced during scaling, rollout, rollback, or self-healing.
- A Service gives the app a stable name and virtual IP inside the cluster.
- The Service load balances traffic across Pods selected by labels.

`ClusterIP` means the Service is reachable inside the cluster. It does not create an external load balancer.

Inspect how the Service finds Pods:

```bash
kubectl describe svc nginx-demo -n lab
kubectl get endpointslices -n lab -l kubernetes.io/service-name=nginx-demo
kubectl get pods --show-labels -n lab
```

Command breakdown:

- `describe svc nginx-demo`: show detailed information about the `nginx-demo` Service.
- `get endpointslices -l kubernetes.io/service-name=nginx-demo`: show the modern Kubernetes backend records for that Service.
- `get pods --show-labels`: show Pod labels so you can compare them with the Service selector.
- `-n lab`: inspect resources in the `lab` namespace.

What to look for:

- The Service selector should match the nginx Pod labels.
- The EndpointSlice list should contain the Pod IPs behind the Service.
- If the selector does not match any Pods, the Service exists but sends traffic nowhere.

EndpointSlices replaced the older Endpoints API as the scalable way Kubernetes tracks Service backends. You may still see `kubectl get endpoints` in older examples, but EndpointSlices are the better habit now.

So what? Services are the bridge between changing Pods and stable networking. In EKS, an internal `ClusterIP` Service still works the same way, while external access usually adds an AWS load balancer or ingress controller in front of it.

## Access The App

Forward a local port to the Service:

```bash
kubectl port-forward svc/nginx-demo 8080:80 -n lab
```

Command breakdown:

- `port-forward`: open a temporary tunnel from your local machine into the cluster.
- `svc/nginx-demo`: target the Service named `nginx-demo`. `svc` is short for `service`.
- `8080:80`: forward local port `8080` to Service port `80`.
- `-n lab`: find the Service in the `lab` namespace.

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
kubectl get all -n lab
```

Command breakdown:

- `get all`: list a common set of resource types in one command.
- `-n lab`: list resources from the `lab` namespace.

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
kubectl get events -A --sort-by=.metadata.creationTimestamp
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace>
kubectl exec -it <pod> -n <namespace> -- sh
kubectl get svc -A
kubectl get endpointslices -A
kubectl get ingress -A
kubectl get pvc -A
```

Command breakdown:

- `-A` is short for `--all-namespaces`.
- `events` are Kubernetes activity records, such as scheduling, image pull, and startup messages.
- `--sort-by=.metadata.creationTimestamp` sorts events by when Kubernetes created the Event objects.
- `<pod>` and `<namespace>` are placeholders. Replace them with real names from your cluster.
- `logs` prints container stdout and stderr.
- `exec -it ... -- sh` starts an interactive shell inside a running container. The `--` separates `kubectl` options from the command you want to run in the container.
- `endpointslices` show which Pod IPs are behind Services.

Why these commands are grouped together:

- `get pods -A` answers "what is running, and where?"
- `get events -A --sort-by=.metadata.creationTimestamp` answers "what recently happened in the cluster?"
- `describe pod` answers "what does Kubernetes know about this Pod's scheduling, image pulls, restarts, and events?"
- `logs` answers "what did the application process write to stdout or stderr?"
- `exec` answers "what can I inspect from inside the running container?"
- `get svc -A` answers "what stable network endpoints exist?"
- `get endpointslices -A` answers "which Pods are actually backing those Services?"
- `get ingress -A` answers "what HTTP routes from outside the cluster exist?"
- `get pvc -A` answers "what storage claims exist?"

So what? This checklist separates Kubernetes problems from application problems. For example, an image pull error is different from nginx starting successfully but returning the wrong content.

## Describe A Deployment

Inspect the Deployment controller's view of the world:

```bash
kubectl describe deployment nginx-demo -n lab
```

Command breakdown:

- `describe`: show detailed information, status, and events for one resource.
- `deployment nginx-demo`: target the Deployment named `nginx-demo`.
- `-n lab`: look in the `lab` namespace.

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
kubectl get pods -n lab
kubectl describe pod <pod-name> -n lab
```

Command breakdown:

- `get pods -n lab`: list Pods so you can copy the real Pod name.
- `describe pod <pod-name>`: show detailed information for one Pod.
- `<pod-name>` is a placeholder. Replace it with a real name from `kubectl get pods -n lab`.
- `-n lab`: look in the `lab` namespace.

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
kubectl logs <pod-name> -n lab
```

For multi-container Pods:

```bash
kubectl logs <pod-name> -c <container-name> -n lab
```

Command breakdown:

- `logs <pod-name>`: print logs from a Pod's default container.
- `-c <container-name>`: choose a specific container when a Pod has more than one.
- `-n lab`: read logs from a Pod in the `lab` namespace.

Why you are running this:

- Kubernetes can tell you whether the container started.
- Application logs tell you what the process did after it started.
- This is how you move from "Kubernetes problem" to "application problem."

For nginx, the logs are not exciting until traffic reaches it. Try loading `http://localhost:8080` while `port-forward` is running, then run `kubectl logs <pod-name> -n lab` again.

So what? ARC runners, Coder workspace agents, ingress controllers, and app workloads all rely heavily on logs. `describe` explains platform state; `logs` explains process behavior.

## Test Self-Healing

Delete one Pod:

```bash
kubectl get pods -n lab
kubectl delete pod <pod-name> -n lab
kubectl get pods -n lab
```

Command breakdown:

- `delete pod <pod-name>`: delete one Pod by name.
- `<pod-name>` is a placeholder. Replace it with one of the real nginx Pod names.
- `get pods -n lab`: list Pods before and after deletion so you can see the replacement appear.
- `-n lab`: delete and list Pods in the `lab` namespace.

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
kubectl set image deployment/nginx-demo nginx=nginx:1.26-alpine -n lab
kubectl rollout status deployment nginx-demo -n lab
```

Command breakdown:

- `set image`: update the container image on an existing workload.
- `deployment/nginx-demo`: target the Deployment named `nginx-demo`. The slash form means `resource-type/resource-name`.
- `nginx=nginx:1.26-alpine`: set the container named `nginx` to use the image `nginx:1.26-alpine`.
- `rollout status`: watch the Deployment update until it succeeds or fails.
- `-n lab`: update and watch the Deployment in the `lab` namespace.

Why you are running this:

- You are changing the Deployment's Pod template.
- Kubernetes responds by gradually replacing old Pods with new Pods.
- `rollout status` waits and tells you whether the update completes.

Watch the rollout:

```bash
kubectl get pods -n lab
kubectl describe deployment nginx-demo -n lab
kubectl rollout history deployment nginx-demo -n lab
```

Command breakdown:

- `get pods -n lab`: watch which Pods are old, new, running, or terminating.
- `describe deployment nginx-demo -n lab`: inspect the Deployment's current rollout details.
- `rollout history`: list recorded Deployment revisions.

What to look for:

- New Pods are created with the new image.
- Old Pods are terminated after replacements become available.
- Rollout history records Deployment revisions.

So what? This is the same basic mechanism used for application deploys in real clusters. Later, Helm, Terraform, GitHub Actions, and GitOps tools may trigger the change, but the Kubernetes rollout behavior is the same.

## Roll Back

Undo the previous rollout:

```bash
kubectl rollout undo deployment nginx-demo -n lab
kubectl rollout status deployment nginx-demo -n lab
```

Command breakdown:

- `rollout undo`: roll a Deployment back to its previous revision.
- `deployment nginx-demo`: target the `nginx-demo` Deployment.
- `rollout status`: watch the rollback complete.
- `-n lab`: operate in the `lab` namespace.

Why you are running this:

- You are practicing how to recover from a bad Deployment update.
- Kubernetes can return to the previous ReplicaSet revision.
- This gives you a quick operational escape hatch during labs.

Check the result:

```bash
kubectl rollout history deployment nginx-demo -n lab
kubectl describe deployment nginx-demo -n lab
```

Command breakdown:

- `rollout history`: confirm the Deployment still has recorded revisions.
- `describe deployment`: inspect the image, replica status, and events after rollback.

So what? Rollback is helpful, but it is not a replacement for good release practices. In production, you also care about database migrations, config changes, external dependencies, and observability.

## Clean Up

Delete the namespace:

```bash
kubectl delete namespace lab
```

Command breakdown:

- `delete namespace lab`: delete the Namespace named `lab`.
- Deleting a namespace also deletes namespaced resources inside it, including this lab's Deployment, ReplicaSet, Pods, and Service.

Why you are running this:

- The namespace contains all the lab resources.
- Deleting it removes the Deployment, ReplicaSet, Pods, and Service together.
- Cleanup keeps later labs from being confusing.

Confirm cleanup:

```bash
kubectl get namespace lab
kubectl get pods -n lab
```

Command breakdown:

- `get namespace lab`: check whether the Namespace still exists.
- `get pods -n lab`: check whether Pods can still be listed from that namespace.

What to expect:

- The namespace may briefly show as `Terminating`.
- After deletion completes, commands against `lab` should report that the namespace was not found.

So what? In AWS, cleanup also controls cost. Namespaces alone do not delete EKS clusters, EC2 nodes, load balancers, or EBS volumes unless those resources are managed as part of the deleted Kubernetes objects. Always understand what layer owns the billable resource.

## Apply The YAML App

Now repeat the same idea declaratively. Instead of creating resources one command at a time, apply the manifest in this repo:

```bash
kubectl apply -f part-01-local-kubernetes/manifests/hello-k8s.yaml
kubectl get all -n hello
kubectl get endpointslices -n hello -l kubernetes.io/service-name=hello-web
```

Command breakdown:

- `apply -f`: send the YAML file to the Kubernetes API server and ask Kubernetes to create or update the objects described in it.
- `hello-k8s.yaml`: defines a Namespace, Deployment, and Service.
- `-n hello`: inspect the namespace created by the manifest.
- `endpointslices -l kubernetes.io/service-name=hello-web`: show the Pod IPs backing the `hello-web` Service.

Why you are running this:

- You are moving from imperative commands to declarative desired state.
- The YAML file is repeatable and reviewable.
- This introduces resource requests and limits, which the one-line `kubectl create deployment` command skipped.

Inspect the manifest after applying it:

```bash
kubectl describe deployment hello-web -n hello
kubectl get pods -n hello --show-labels
kubectl describe svc hello-web -n hello
```

What to look for:

- The Deployment should want two replicas.
- The Pod template should include the nginx image, container port, CPU request, memory request, CPU limit, and memory limit.
- The Service selector should match the Pod label `app.kubernetes.io/name=hello-web`.
- The EndpointSlice should contain one address per ready backend Pod.

Access it the same way as before:

```bash
kubectl port-forward -n hello svc/hello-web 8080:80
```

Open:

```text
http://localhost:8080
```

Stop port forwarding with `Ctrl+C`.

Clean up the YAML-managed app:

```bash
kubectl delete -f part-01-local-kubernetes/manifests/hello-k8s.yaml
```

So what? `kubectl apply` is still changing Kubernetes desired state directly. The difference is that the desired state lives in a file you can read, diff, commit, and reuse.

## Rebuild With Terraform

The Terraform module creates the same app shape through the Kubernetes provider:

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

Command breakdown:

- `terraform init`: download the Kubernetes provider.
- `terraform fmt`: format the `.tf` files.
- `terraform validate`: check the Terraform syntax and provider configuration.
- `terraform plan`: preview the Kubernetes resources Terraform will create, change, or destroy.
- `terraform apply`: make the planned changes.
- `terraform output port_forward_command`: print the `kubectl port-forward` command for the Terraform-managed Service.
- `terraform destroy`: delete the resources Terraform created.

After `terraform apply`, run the command printed by `terraform output port_forward_command` in a separate terminal if you want to test the app in your browser. Stop it with `Ctrl+C`, then run `terraform destroy`.

Why the Terraform namespace is different:

- The YAML app uses `hello`.
- The Terraform module defaults to `tf-hello`.
- Terraform should not silently take ownership of resources you created with `kubectl apply`.

What you should learn here:

- Kubernetes stores desired state in the cluster.
- Terraform stores its own state for the resources it manages.
- Terraform can manage Kubernetes objects, but it adds a second ownership layer you must respect.
- `terraform plan` is the habit that connects syntax to real changes.

Try one controlled change:

```bash
terraform plan -var='replicas=3'
```

Read the plan before applying anything. You should be able to predict that Terraform wants the Deployment replica count to change from two to three.

So what? This is the bridge to Coder templates and EKS infrastructure. Later, Terraform will create AWS resources such as VPCs, IAM roles, EKS clusters, and node groups. Here it is easier and cheaper to learn the same planning habit against local Kubernetes objects.

## Core Mental Model

```text
Deployment -> ReplicaSet -> Pods -> Containers

Service -> selector/labels -> Pods

EndpointSlice -> current backend IPs for a Service

kubectl -> Kubernetes API server -> desired state -> controllers -> actual running Pods

Terraform -> Kubernetes provider -> Kubernetes API server -> desired state
```

The important habit is to ask which layer you are inspecting:

- Context and kubeconfig: which cluster am I changing?
- Node: where can Pods run?
- Namespace: where does this object live?
- Deployment: what desired app state did I declare?
- ReplicaSet: what Pod copies are being maintained?
- Pod: what is actually running?
- Service: how does traffic find the Pods?
- EndpointSlice: which Pod IPs are currently behind the Service?
- Events and logs: what happened when Kubernetes or the app tried to do the work?
- Terraform state: which Kubernetes resources does Terraform think it owns?

## Mapping To EKS

| Local | EKS |
|------|------|
| docker-desktop | EKS cluster |
| local Docker Desktop nodes | EC2 / Fargate worker capacity |
| ClusterIP | ClusterIP |
| EndpointSlice | EndpointSlice |
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
- How EndpointSlices show the current Service backends
- Service vs port-forward
- Why YAML, Terraform, and imperative commands are different ownership models
- How to debug a failing Pod using events, `describe`, and logs
- Why the same Kubernetes commands still matter when the cluster moves to EKS
