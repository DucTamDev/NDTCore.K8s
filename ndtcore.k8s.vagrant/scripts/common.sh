#!/bin/bash
# Common setup script for all Kubernetes nodes (Control Plane & Workers)

set -euxo pipefail

# ==========================
# * Configure DNS
# ==========================
sudo mkdir -p /etc/systemd/resolved.conf.d
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dns_servers.conf
[Resolve]
DNS=${DNS_SERVERS}
EOF
sudo systemctl restart systemd-resolved

# ==========================
# * Disable Swap
# ==========================
sudo swapoff -a
# Ensure swap stays off after reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true

# ==========================
# * Kernel Module Configuration
# ==========================
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# ==========================
# * System Configuration for Kubernetes
# ==========================
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# ==========================
# * Install Dependencies
# ==========================
sudo apt-get update -y
sudo apt-get install -y software-properties-common curl apt-transport-https ca-certificates jq

# ==========================
# * Install CRI-O Runtime
# ==========================
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" |
    sudo tee /etc/apt/sources.list.d/cri-o.list

sudo apt-get update -y
sudo apt-get install -y cri-o
sudo systemctl enable --now crio
sudo systemctl start crio.service

echo "CRI-O runtime installed successfully"

# ==========================
# * Install Kubernetes Components (Kubelet, Kubectl, Kubeadm)
# ==========================
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION_SHORT/deb/Release.key | 
    sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION_SHORT/deb/ /" | 
    sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet="$KUBERNETES_VERSION" kubectl="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION"

# Prevent Kubernetes packages from being automatically updated
sudo apt-mark hold kubelet kubectl kubeadm cri-o

# ==========================
# * Set Node IP for Kubelet
# ==========================
local_ip="$(ip -json addr show eth1 | jq -r '.[] | .addr_info[]? | select(.family=="inet") | .local')"

cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
${ENVIRONMENT}
EOF
