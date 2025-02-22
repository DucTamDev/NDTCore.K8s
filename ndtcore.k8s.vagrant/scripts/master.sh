#!/bin/bash
# Setup script for Kubernetes Control Plane (Master Node)

set -euxo pipefail

NODENAME=$(hostname -s)
CONFIG_PATH="/vagrant/configs"

# ==========================
# * Preflight Checks & Init
# ==========================
echo "Pulling Kubernetes images..."
sudo kubeadm config images pull
echo "Preflight Check Passed: Downloaded All Required Images"

echo "Initializing Kubernetes Control Plane..."
sudo kubeadm init \
    --apiserver-advertise-address="$CONTROL_IP" \
    --apiserver-cert-extra-sans="$CONTROL_IP" \
    --pod-network-cidr="$POD_CIDR" \
    --service-cidr="$SERVICE_CIDR" \
    --node-name "$NODENAME" \
    --ignore-preflight-errors Swap

# ==========================
# * Configure kubectl for Root User
# ==========================
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"

# ==========================
# * Save Configs to Shared Folder
# ==========================
echo "Saving Kubernetes config and join command..."
sudo mkdir -p "$CONFIG_PATH"
sudo rm -f "$CONFIG_PATH/"*

sudo cp -i /etc/kubernetes/admin.conf "$CONFIG_PATH/config"
sudo kubeadm token create --print-join-command > "$CONFIG_PATH/join.sh"
sudo chmod +x "$CONFIG_PATH/join.sh"

# ==========================
# * Install Calico Network Plugin
# ==========================
echo "Installing Calico network plugin..."
curl -fsSL "https://raw.githubusercontent.com/projectcalico/calico/master/manifests/calico.yaml" -o calico.yaml
kubectl apply -f calico.yaml

# ==========================
# * Configure kubectl for Vagrant User
# ==========================
echo "Configuring kubectl for vagrant user..."
sudo -i -u vagrant bash << EOF
mkdir -p /home/vagrant/.kube
cp -i "$CONFIG_PATH/config" /home/vagrant/.kube/config
chown 1000:1000 /home/vagrant/.kube/config
EOF

# ==========================
# * Install Metrics Server
# ==========================
echo "Installing Metrics Server..."
kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml

echo "Kubernetes Control Plane setup completed successfully!"
