# Coder Kubernetes Template Practice

This directory is for learning how Coder templates use Terraform to create Kubernetes resources.

Use it after Coder is running locally or on EKS:

```bash
coder templates push kubernetes-practice -d examples/terraform/coder-template-kubernetes
```

Practice changes:

- Add a `coder_parameter` for CPU or memory.
- Change the workspace image.
- Add a `kubernetes_persistent_volume_claim`.
- Add labels that help track owner, workspace, environment, and cost.

