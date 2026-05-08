# ============================================================
# Dev Environment - Variable Values
#
# Safe to commit — no secrets here.
# ssh_public_key is passed via CLI or CI/CD secret:
#   terraform apply -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
# ============================================================

prefix      = "akslab"
environment = "dev"
location    = "canadacentral"
project     = "aks-argocd-lab"
owner       = "platform-team"

# Add your Entra ID user object ID here
# Get it with: az ad signed-in-user show --query id -o tsv
admin_group_members = []
dev_group_members   = []