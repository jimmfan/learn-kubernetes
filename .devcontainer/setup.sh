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

patch_vscode_global_navigator_guard() {
  local vscode_server_root="/vscode/vscode-server/bin/linux-${arch}"

  if [ ! -d "$vscode_server_root" ]; then
    return
  fi

  python3 - "$vscode_server_root" <<'PY'
from pathlib import Path
import sys

server_root = Path(sys.argv[1])
old = 'Qy.supportGlobalNavigator||Object.defineProperty(globalThis,"navigator",{get:()=>{ta(new ea("navigator is now a global in nodejs, please see https://aka.ms/vscode-extensions/navigator for additional info on this error."))}});'
new = 'Qy.supportGlobalNavigator||globalThis.navigator||Object.defineProperty(globalThis,"navigator",{value:{userAgent:"Node.js"},configurable:!0});'

for path in server_root.glob("*/out/vs/workbench/api/node/extensionHostProcess.js"):
    text = path.read_text()
    if old not in text or new in text:
        continue
    path.write_text(text.replace(old, new))
    print(f"Patched VS Code extension host global navigator guard: {path}")
PY
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
  bash-completion \
  bubblewrap \
  ca-certificates \
  curl \
  dnsutils \
  git \
  gnupg \
  iproute2 \
  jq \
  less \
  lsb-release \
  make \
  nano \
  netcat-openbsd \
  python3 \
  python3-pip \
  python3-venv \
  shellcheck \
  tree \
  unzip

patch_vscode_global_navigator_guard

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

if ! command_exists terraform-ls; then
  terraform_ls_version="$(curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/terraform-ls | jq -r .current_version)"
  curl -fsSL -o "$tmp_dir/terraform-ls.zip" \
    "https://releases.hashicorp.com/terraform-ls/${terraform_ls_version}/terraform-ls_${terraform_ls_version}_linux_${arch}.zip"
  unzip -q "$tmp_dir/terraform-ls.zip" -d "$tmp_dir/terraform-ls"
  install -m 0755 "$tmp_dir/terraform-ls/terraform-ls" "$install_dir/terraform-ls"
fi

if ! command_exists tflint; then
  curl -fsSL -o "$tmp_dir/tflint.zip" \
    "https://github.com/terraform-linters/tflint/releases/latest/download/tflint_linux_${arch}.zip"
  unzip -q "$tmp_dir/tflint.zip" -d "$tmp_dir/tflint"
  install -m 0755 "$tmp_dir/tflint/tflint" "$install_dir/tflint"
fi

if ! command_exists yq; then
  curl -fsSL -o "$tmp_dir/yq" \
    "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${arch}"
  install -m 0755 "$tmp_dir/yq" "$install_dir/yq"
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

if ! command_exists gh; then
  gh_version="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | jq -r .tag_name | sed 's/^v//')"
  curl -fsSL -o "$tmp_dir/gh.tar.gz" \
    "https://github.com/cli/cli/releases/latest/download/gh_${gh_version}_linux_${arch}.tar.gz"
  tar -xzf "$tmp_dir/gh.tar.gz" -C "$tmp_dir"
  install -m 0755 "$tmp_dir/gh_${gh_version}_linux_${arch}/bin/gh" "$install_dir/gh"
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

bashrc="$HOME/.bashrc"
kubectl_alias_marker="# learn-kubernetes kubectl shortcuts"
touch "$bashrc"
if ! grep -Fq "$kubectl_alias_marker" "$bashrc"; then
  {
    echo
    echo "$kubectl_alias_marker"
    echo "alias k=kubectl"
    echo "if command -v kubectl >/dev/null 2>&1; then"
    echo "  source <(kubectl completion bash)"
    echo "  complete -o default -F __start_kubectl k"
    echo "fi"
  } >> "$bashrc"
fi

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

echo "terraform-ls:"
terraform-ls version

echo "tflint:"
tflint --version

echo "yq:"
yq --version

echo "aws:"
aws --version

echo "gh:"
gh --version | head -n 1

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
