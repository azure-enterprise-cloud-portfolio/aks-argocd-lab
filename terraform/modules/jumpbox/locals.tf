# ============================================================
# Jumpbox Module - Locals
#
# Centralizes all name construction and computed values.
#
# This module creates:
#   - Linux VM (Ubuntu 22.04 LTS)     → admin jumpbox
#   - Network Interface               → private IP only
#   - NSG for Jumpbox subnet          → deny all except Bastion
#
# Why a jumpbox?
#   The AKS API server has no public endpoint.
#   The jumpbox sits inside the same VNet and acts as the
#   only machine that can run kubectl against the cluster.
#   Access to the jumpbox itself goes through Azure Bastion
#   (HTTPS only — no open SSH port on the internet).
# ============================================================

locals {
  # ── Name Prefix ───────────────────────────────────────────
  name_prefix = "${var.prefix}-${var.environment}"

  # ── Resource Names ────────────────────────────────────────
  vm_name   = "${local.name_prefix}-jumpbox"
  nic_name  = "${local.name_prefix}-jumpbox-nic"
  nsg_name  = "${local.name_prefix}-nsg-jumpbox"
  disk_name = "${local.name_prefix}-jumpbox-osdisk"

  # ── Startup Script ────────────────────────────────────────
  # Injected as cloud-init (custom_data) on first boot.
  # Installs all tools needed to manage the AKS cluster:
  #   - Azure CLI    → az aks get-credentials, az login --identity
  #   - kubectl      → cluster management
  #   - Helm         → chart deployments
  #   - kubelogin    → Entra ID authentication for kubectl
  #   - ArgoCD CLI   → manage ArgoCD applications
  #   - k9s          → terminal UI for Kubernetes
  startup_script = <<-EOF
    #!/bin/bash
    set -euo pipefail
    exec > /var/log/jumpbox-init.log 2>&1

    echo "=== Starting jumpbox initialization ==="

    # ── Azure CLI ──────────────────────────────────────────
    echo "Installing Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash

    # ── kubectl ────────────────────────────────────────────
    echo "Installing kubectl..."
    KUBECTL_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
    curl -sLO "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/kubectl

    # ── Helm ───────────────────────────────────────────────
    echo "Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # ── kubelogin ──────────────────────────────────────────
    # Required for Entra ID authentication with kubectl.
    # Converts kubeconfig to use az cli token flow.
    echo "Installing kubelogin..."
    curl -sLo kubelogin.zip \
      https://github.com/Azure/kubelogin/releases/latest/download/kubelogin-linux-amd64.zip
    unzip -q kubelogin.zip
    mv bin/linux_amd64/kubelogin /usr/local/bin/kubelogin
    rm -rf kubelogin.zip bin/

    # ── ArgoCD CLI ─────────────────────────────────────────
    echo "Installing ArgoCD CLI..."
    ARGOCD_VERSION=$(curl -sL \
      https://api.github.com/repos/argoproj/argo-cd/releases/latest \
      | grep '"tag_name"' | cut -d'"' -f4)
    curl -sLo /usr/local/bin/argocd \
      "https://github.com/argoproj/argo-cd/releases/download/$${ARGOCD_VERSION}/argocd-linux-amd64"
    chmod +x /usr/local/bin/argocd

    # ── k9s ────────────────────────────────────────────────
    echo "Installing k9s..."
    K9S_VERSION=$(curl -sL \
      https://api.github.com/repos/derailed/k9s/releases/latest \
      | grep '"tag_name"' | cut -d'"' -f4)
    curl -sL \
      "https://github.com/derailed/k9s/releases/download/$${K9S_VERSION}/k9s_Linux_amd64.tar.gz" \
      | tar xz -C /usr/local/bin k9s

    # ── kubectl aliases ────────────────────────────────────
    echo "Configuring shell aliases..."
    cat >> /home/azureuser/.bashrc <<'BASHRC'

# Kubernetes aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kns='kubectl config set-context --current --namespace'
alias kctx='kubectl config current-context'

# Auto-complete
source <(kubectl completion bash)
complete -F __start_kubectl k
BASHRC

    echo "=== Jumpbox initialization complete ==="
    echo "Tools installed: azure-cli kubectl helm kubelogin argocd k9s"
    touch /tmp/jumpbox-ready
  EOF

  # ── Common Tags ───────────────────────────────────────────
  common_tags = merge(
    {
      environment = var.environment
      project     = var.project
      module      = "jumpbox"
      managed_by  = "terraform"
      owner       = var.owner
    },
    var.tags
  )
}