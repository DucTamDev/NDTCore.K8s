#!/bin/bash
# Setup script for Kubernetes Worker Node

set -euxo pipefail

CONFIG_PATH="/vagrant/configs"
JOIN_SCRIPT="$CONFIG_PATH/join.sh"

# ==========================
# Configure Worker Node
# ==========================

# Join Worker Node to Cluster
if [[ -f "$JOIN_SCRIPT" ]]; then
    echo "Joining the Kubernetes cluster..."
    /bin/bash "$JOIN_SCRIPT" -v
else
    echo "ERROR: Join script not found at $JOIN_SCRIPT"
    exit 1
fi

# ==========================
# Configure kubectl for Vagrant User
# ==========================

sudo -i -u vagrant bash << EOF
mkdir -p /home/vagrant/.kube
cp -i "$CONFIG_PATH/config" /home/vagrant/.kube/config
chown 1000:1000 /home/vagrant/.kube/config
EOF

# ==========================
# Label Node as Worker
# ==========================

NODENAME=$(hostname -s)
echo "Labeling node '$NODENAME' as worker..."
kubectl label node "$NODENAME" node-role.kubernetes.io/worker=worker || true

echo "Kubernetes Worker Node setup completed successfully."
