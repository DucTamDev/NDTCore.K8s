#!/bin/bash
# Deploys the Kubernetes dashboard if enabled in settings.yaml

set -euxo pipefail

CONFIG_PATH="/vagrant/configs"
SETTINGS_FILE="/vagrant/settings.yaml"

# ==========================
# Check Dashboard Version
# ==========================

DASHBOARD_VERSION=$(awk -F ': ' '/^\s*dashboard:/ {print $2}' "$SETTINGS_FILE" | tr -d '\r')

if [[ -z "$DASHBOARD_VERSION" ]]; then
    echo "Dashboard installation skipped (not enabled in settings.yaml)."
    exit 0
fi

# ==========================
# Wait for Metrics Server
# ==========================

echo "Waiting for Metrics Server to be ready..."
until sudo -i -u vagrant kubectl get pods -A -l k8s-app=metrics-server | awk 'split($3, a, "/") && a[1] != a[2] { print $0; }' | grep -vq "RESTARTS"; do
    sleep 5
done

echo "Metrics Server is ready. Installing Kubernetes Dashboard..."

# ==========================
# Deploy Dashboard
# ==========================

sudo -i -u vagrant kubectl create namespace kubernetes-dashboard --dry-run=client -o yaml | sudo -i -u vagrant kubectl apply -f -

echo "Creating dashboard admin user..."

cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: admin-user
EOF

cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# ==========================
# Deploy Dashboard Components
# ==========================

echo "Deploying Kubernetes Dashboard..."
sudo -i -u vagrant kubectl apply -f "https://raw.githubusercontent.com/kubernetes/dashboard/v${DASHBOARD_VERSION}/aio/deploy/recommended.yaml"

# ==========================
# Retrieve Access Token
# ==========================

DASHBOARD_TOKEN=$(sudo -i -u vagrant kubectl -n kubernetes-dashboard get secret admin-user -o go-template="{{.data.token | base64decode}}")

echo "$DASHBOARD_TOKEN" > "${CONFIG_PATH}/token"
echo "Dashboard access token saved to: ${CONFIG_PATH}/token"

# ==========================
# Dashboard Access Information
# ==========================

cat <<EOF

Use the following token to log in to the Kubernetes Dashboard:
$DASHBOARD_TOKEN

Access Dashboard at:
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=kubernetes-dashboard

EOF
