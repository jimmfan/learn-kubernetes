# Local Kubernetes Terraform Practice

This recreates `part-01-local-kubernetes/manifests/hello-k8s.yaml` with Terraform and the Kubernetes provider.

Practice loop:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output port_forward_command
terraform destroy
```

Things to try:

- Change `replicas` from `2` to `3` and inspect the plan.
- Change the container image tag and watch the deployment roll out.
- Add a label to the Deployment and decide whether the Service selector should change.
- Break the Service selector, apply it, then debug with `kubectl describe svc`.

