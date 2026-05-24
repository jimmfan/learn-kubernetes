# EKS Terraform Starter

This is a small but real EKS lab. It creates paid AWS infrastructure:

- VPC across 2-3 availability zones
- public subnets tagged for internet-facing load balancers
- private subnets tagged for internal load balancers
- single NAT gateway for private node egress
- EKS control plane
- EKS managed node group
- core EKS add-ons
- cluster creator admin access

It is intentionally conservative. It does not yet install Coder, RDS, ExternalDNS, cert-manager, the AWS Load Balancer Controller, or production-grade observability.

## Cost Warning

This creates billable resources. The EKS control plane, NAT gateway, EC2 worker nodes, EBS volumes, and any load balancers you create from Kubernetes can all cost money.

Destroy the lab when you are done:

```bash
terraform destroy
```

## Prerequisites

- Terraform `>= 1.5.7`
- AWS CLI
- AWS credentials configured for the target account
- Enough AWS permissions to create VPC, IAM, EC2, and EKS resources

## Deploy

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Configure `kubectl`:

```bash
aws eks update-kubeconfig --region us-east-1 --name coder-learning
kubectl get nodes
```

You can also print the generated command:

```bash
terraform output -raw update_kubeconfig_command
```

## Defaults

- Region: `us-east-1`
- Kubernetes version: `1.33`
- Node type: `t3.medium`
- Desired nodes: `2`
- NAT gateways: `1`
- VPC CIDR: `10.20.0.0/16`

## Why Managed Node Groups

This lab uses EKS managed node groups rather than EKS Auto Mode. Managed node groups make the underlying compute model visible while still letting AWS manage the node group lifecycle.

That is useful for learning:

- how nodes join a cluster
- how private subnets and NAT affect node egress
- how Kubernetes Services discover load-balancer subnets
- where IAM, EC2, and EKS responsibilities meet

## Load Balancers

The VPC subnets are tagged so Kubernetes load balancer integrations can discover them:

- public subnets: `kubernetes.io/role/elb = 1`
- private subnets: `kubernetes.io/role/internal-elb = 1`

This Terraform does not install the AWS Load Balancer Controller yet. Add that later when you are ready to practice Ingress, ALB, and more realistic Coder exposure.

## Next Layers

Good follow-up steps:

- deploy a tiny Kubernetes workload
- expose it with a `Service` of type `LoadBalancer`
- add the AWS Load Balancer Controller
- deploy Coder with Helm
- move Coder Postgres to RDS
- add DNS and TLS
- add EBS CSI storage
