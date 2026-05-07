# AKS ArgoCD GitOps Lab

A production-grade Azure Kubernetes Service (AKS) lab demonstrating private cluster deployment, Entra ID RBAC, GitOps with ArgoCD, and service mesh with Istio — across **Dev** and **Prod** environments.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Subscription                        │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                  Resource Group                       │  │
│  │                                                      │  │
│  │  ┌─────────┐   ┌──────────┐   ┌──────────────────┐  │  │
│  │  │  Bastion │   │ Jumpbox  │   │   Private AKS    │  │  │
│  │  │ (HTTPS) │──▶│   VM     │──▶│                  │  │  │
│  │  └─────────┘   └──────────┘   │  ┌────────────┐  │  │  │
│  │                               │  │  argocd ns │  │  │  │
│  │  ┌─────────┐                  │  │  myapp ns  │  │  │  │
│  │  │   ACR   │◀─────────────────│  │  bookinfo  │  │  │  │
│  │  └─────────┘                  │  └────────────┘  │  │  │
│  │                               │  Network Policies │  │  │
│  │  ┌─────────┐                  │  Entra ID RBAC   │  │  │
│  │  │  Key    │◀─────────────────│  Istio Mesh      │  │  │
│  │  │  Vault  │  CSI Driver      └──────────────────┘  │  │
│  │  └─────────┘                                        │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │ GitOps sync
              ┌─────────────▼──────────────┐
              │         GitHub Repo         │
              │   helm/  argocd/  terraform/│
              └─────────────────────────────┘
```

---

## What This Lab Covers

| Area | Technology | JD Requirement |
|------|-----------|----------------|
| Private Cluster | AKS private API server | Kubernetes & Cloud-Native |
| IaC Modules | Terraform modules | Infrastructure as Code |
| Identity | Azure Entra ID + Managed Identity | Security & Governance |
| RBAC | Azure RBAC + K8s RBAC | Security & Governance |
| Network Policy | Azure CNI + Network Policy | Kubernetes Networking |
| GitOps | ArgoCD App-of-Apps | DevOps & GitOps |
| App Packaging | Helm charts | DevOps & GitOps |
| Service Mesh | Istio + mTLS | Service Mesh & Networking |
| Secrets | Key Vault + CSI Driver | Security & Governance |
| Jumpbox Access | Azure Bastion | Best Practice |

---

## Repository Structure

```
aks-argocd-lab/
├── terraform/
│   ├── modules/
│   │   ├── networking/        # VNet, subnets, Bastion
│   │   ├── identity/          # Managed Identity, Entra ID groups
│   │   ├── aks/               # AKS cluster
│   │   └── jumpbox/           # Jumpbox VM
│   └── envs/
│       ├── dev/               # Dev environment
│       └── prod/              # Prod environment
├── helm/
│   └── myapp/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml
│       ├── values-prod.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           └── networkpolicy.yaml
├── argocd/
│   ├── dev/
│   │   ├── root-app.yaml      # App-of-Apps root
│   │   ├── myapp.yaml
│   │   └── bookinfo.yaml
│   └── prod/
│       ├── root-app.yaml
│       ├── myapp.yaml
│       └── bookinfo.yaml
└── README.md
```

---

## Environments

| Setting | Dev | Prod |
|---------|-----|------|
| Node count | 2 | 3 |
| VM size | Standard_D2s_v3 | Standard_D4s_v3 |
| App replicas | 1 | 3 |
| ArgoCD sync | Automatic | Manual approval |
| Location | canadacentral | canadacentral |

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Azure CLI | >= 2.60 | `brew install azure-cli` |
| Terraform | >= 1.7 | `brew install terraform` |
| kubectl | >= 1.29 | `brew install kubectl` |
| Helm | >= 3.14 | `brew install helm` |
| kubelogin | latest | `brew install Azure/kubelogin/kubelogin` |
| ArgoCD CLI | latest | `brew install argocd` |

---

## Getting Started

### 1. Login to Azure

```bash
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

### 2. Deploy Dev Environment

```bash
cd terraform/envs/dev
terraform init
terraform plan
terraform apply -auto-approve
```

### 3. Connect to Private Cluster via Jumpbox

```bash
# Connect via Azure Bastion
az network bastion ssh \
  --name akslab-dev-bastion \
  --resource-group akslab-dev-rg \
  --target-resource-id $(az vm show \
      --resource-group akslab-dev-rg \
      --name akslab-dev-jumpbox \
      --query id -o tsv) \
  --auth-type ssh-key \
  --username azureuser \
  --ssh-key ~/.ssh/id_rsa
```

### 4. Get AKS Credentials (inside Jumpbox)

```bash
az login --identity
az aks get-credentials \
  --resource-group akslab-dev-rg \
  --name akslab-dev-aks
kubelogin convert-kubeconfig -l azurecli
kubectl get nodes
```

### 5. Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
```

### 6. Bootstrap GitOps (App-of-Apps)

```bash
kubectl apply -f argocd/dev/root-app.yaml
```

This single command deploys all apps from Git automatically.

---

## Deployed Applications

### myapp
Simple nginx-based web app demonstrating:
- Helm chart packaging with environment-specific values
- GitOps deployment via ArgoCD
- Network policy enforcement (default deny-all)
- Horizontal Pod Autoscaler

### bookinfo
Istio's official microservices demo app demonstrating:
- 4 microservices (productpage, details, reviews, ratings)
- mTLS between all services
- Traffic splitting for canary releases
- Observability via Kiali and Jaeger

---

## GitOps Workflow

```
Developer pushes to Git
        │
        ▼
  GitHub Repository
        │
        │ ArgoCD polls every 3 min
        ▼
  ArgoCD detects diff
        │
        ├── Dev:  Auto-sync ──▶ Apply immediately
        │
        └── Prod: Manual gate ──▶ Human approval ──▶ Apply
```

### Deploy a Change

```bash
# Update image tag in values-dev.yaml
git add helm/myapp/values-dev.yaml
git commit -m "release: bump myapp to v1.1.0"
git push origin main
# ArgoCD auto-syncs within 3 minutes
```

### Rollback via Git

```bash
git revert HEAD
git push origin main
# ArgoCD syncs back to previous state automatically
```

---

## Security Highlights

- **Private AKS API server** — not reachable from the internet
- **Azure Bastion** — no public IP on jumpbox, HTTPS-only access
- **Entra ID RBAC** — Azure AD groups mapped to cluster roles
- **Managed Identity** — no passwords or keys stored anywhere
- **Key Vault CSI Driver** — secrets injected as volume mounts
- **Network Policies** — default deny-all, explicit allow rules only
- **Istio mTLS** — encrypted service-to-service communication

---

## Verification Commands

```bash
# Cluster is private
az aks show \
  --resource-group akslab-dev-rg \
  --name akslab-dev-aks \
  --query "apiServerAccessProfile.enablePrivateCluster"
# → true

# Network policies active
kubectl get networkpolicy --all-namespaces

# Entra ID RBAC enabled
az aks show \
  --resource-group akslab-dev-rg \
  --name akslab-dev-aks \
  --query "aadProfile"

# ArgoCD apps synced
argocd app list

# All pods healthy
kubectl get pods --all-namespaces
```

---

## Cleanup

```bash
# Destroy dev environment
cd terraform/envs/dev
terraform destroy -auto-approve

# Destroy prod environment
cd terraform/envs/prod
terraform destroy -auto-approve
```

---

## Key Concepts

| Concept | Description |
|---------|-------------|
| `private_cluster_enabled = true` | AKS API server only reachable inside VNet |
| `network_policy = "azure"` | Enables Kubernetes NetworkPolicy enforcement |
| `azure_rbac_enabled = true` | Maps Entra ID groups to Kubernetes RBAC |
| ArgoCD `selfHeal = true` | Reverts any manual kubectl changes automatically |
| ArgoCD `prune = true` | Removes resources deleted from Git |
| App-of-Apps pattern | Single root app manages all child apps |
| Helm values per env | `values-dev.yaml` / `values-prod.yaml` override base values |

---

## Author

Built as an interview preparation lab for an Azure Kubernetes Engineer role.  
Covers: Private AKS · Terraform Modules · Entra ID RBAC · ArgoCD GitOps · Istio · Helm · Azure Bastion
