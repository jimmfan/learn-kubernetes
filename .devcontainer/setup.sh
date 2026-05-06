#!/usr/bin/env bash
set -euo pipefail

install_dir="$HOME/.local/bin"
mkdir -p "$install_dir"

export PATH="$install_dir:$PATH"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

arch="$(uname -m)"
case "$arch" in
  x86_64) arch="amd64" ;;
  aarch64|arm64) arch="arm64" ;;
  *) echo "Unsupported architecture: $arch"; exit 1 ;;
esac

kubectl_version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
curl -fsSL -o "$tmp_dir/kubectl" \
  "https://dl.k8s.io/release/${kubectl_version}/bin/linux/${arch}/kubectl"

install -m 0755 "$tmp_dir/kubectl" "$install_dir/kubectl"

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
"$install_dir/kubectl" version --client

echo "Current cluster endpoint:"
"$install_dir/kubectl" config view --minify -o jsonpath='{.clusters[0].cluster.server}' || true
echo

echo "Available contexts:"
"$install_dir/kubectl" config get-contexts || true
