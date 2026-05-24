#!/usr/bin/env bash
set -euo pipefail

install_dir="$HOME/.local/bin"
mkdir -p "$install_dir"

export PATH="$install_dir:$PATH"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

sudo_cmd=()
if [ "$(id -u)" -ne 0 ]; then
  sudo_cmd=(sudo)
fi

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

arch="$(uname -m)"
case "$arch" in
  x86_64) arch="amd64" ;;
  aarch64|arm64) arch="arm64" ;;
  *) echo "Unsupported architecture: $arch"; exit 1 ;;
esac

echo "Installing base packages..."
"${sudo_cmd[@]}" apt-get update
"${sudo_cmd[@]}" apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  git \
  gnupg \
  jq \
  lsb-release \
  make \
  unzip

if ! command_exists kubectl; then
  kubectl_version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSL -o "$tmp_dir/kubectl" \
    "https://dl.k8s.io/release/${kubectl_version}/bin/linux/${arch}/kubectl"

  install -m 0755 "$tmp_dir/kubectl" "$install_dir/kubectl"
fi

if ! command_exists helm; then
  helm_version="$(curl -fsSL https://api.github.com/repos/helm/helm/releases/latest | jq -r .tag_name)"
  curl -fsSL -o "$tmp_dir/helm.tar.gz" \
    "https://get.helm.sh/helm-${helm_version}-linux-${arch}.tar.gz"
  tar -xzf "$tmp_dir/helm.tar.gz" -C "$tmp_dir"
  install -m 0755 "$tmp_dir/linux-${arch}/helm" "$install_dir/helm"
fi

if ! command_exists terraform; then
  curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | "${sudo_cmd[@]}" gpg --dearmor --batch --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    | "${sudo_cmd[@]}" tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

  "${sudo_cmd[@]}" apt-get update
  "${sudo_cmd[@]}" apt-get install -y --no-install-recommends terraform
fi

if ! command_exists aws; then
  aws_arch="$arch"
  case "$aws_arch" in
    amd64) aws_arch="x86_64" ;;
    arm64) aws_arch="aarch64" ;;
  esac

  curl -fsSL -o "$tmp_dir/awscliv2.zip" \
    "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip"
  unzip -q "$tmp_dir/awscliv2.zip" -d "$tmp_dir"
  "${sudo_cmd[@]}" "$tmp_dir/aws/install" --update
fi

if ! command_exists eksctl; then
  curl -fsSL -o "$tmp_dir/eksctl.tar.gz" \
    "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_${arch}.tar.gz"
  tar -xzf "$tmp_dir/eksctl.tar.gz" -C "$tmp_dir"
  install -m 0755 "$tmp_dir/eksctl" "$install_dir/eksctl"
fi

if ! command_exists kind; then
  kind_arch="$arch"
  curl -fsSL -o "$tmp_dir/kind" \
    "https://kind.sigs.k8s.io/dl/latest/kind-linux-${kind_arch}"
  install -m 0755 "$tmp_dir/kind" "$install_dir/kind"
fi

if ! command_exists coder; then
  curl -fsSL https://coder.com/install.sh | sh
fi

mkdir -p "$HOME/.kube"

if [ -f /tmp/host-kube/config ]; then
  cp /tmp/host-kube/config "$HOME/.kube/config"

  sed -i \
    's#https://127.0.0.1:6443#https://kubernetes.docker.internal:6443#g' \
    "$HOME/.kube/config"

  sed -i \
    's#https://host.docker.internal:6443#https://kubernetes.docker.internal:6443#g' \
    "$HOME/.kube/config"
fi

echo "kubectl:"
kubectl version --client

echo "helm:"
helm version --short

echo "terraform:"
terraform version

echo "aws:"
aws --version

echo "eksctl:"
eksctl version

echo "kind:"
kind version

echo "coder:"
coder version || true

echo "Current cluster endpoint:"
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' || true
echo

echo "Available contexts:"
kubectl config get-contexts || true
