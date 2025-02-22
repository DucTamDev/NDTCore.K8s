# Step-by-Step Setup Kubernetes with Vagrant & Kubeadm

## 1. Cấu Hình Trên Tất Cả Các Node

SSH vào từng node:

```bash
vagrant ssh nodemaster
```

```bash
vagrant ssh node01
```

Chạy các lệnh sau trên cả **`nodemaster` và `node01`**.

### Cấu hình DNS (Tùy chọn)

[🔗 Giải thích chi tiết](01_configure_dns.md)

Nếu muốn sử dụng cấu hình DNS như trong script, chạy:

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dns_servers.conf
[Resolve]
DNS=${DNS_SERVERS}
EOF
sudo systemctl restart systemd-resolved
```

### Cập nhật hệ thống

```bash
sudo apt update && sudo apt upgrade -y
```

### Tắt Swap (bắt buộc)

[🔗 Giải thích chi tiết](02_disable_swap.md)

```bash
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
```

Nếu muốn đảm bảo swap luôn tắt sau reboot bằng `crontab`:

```bash
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
```

### Cấu hình kernel modules

[🔗 Giải thích chi tiết](03_enable_kernel_modules.md)

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

### Cấu hình hệ thống cho Kubernetes

[🔗 Giải thích chi tiết](04_configure_sysctl.md)

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

### Cài đặt container runtime

#### Tuỳ chọn 1: Sử dụng Containerd (Mặc định)

```bash
sudo apt install -y containerd.io
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

sudo systemctl restart containerd
sudo systemctl enable containerd
```

#### Tuỳ chọn 2: Sử dụng CRI-O (Thay thế Containerd)

```bash
export CRIO_VERSION=v1.32

curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

sudo apt-get update -y
sudo apt-get install -y cri-o
sudo systemctl enable --now crio
sudo systemctl start crio.service
```

### Cài đặt Kubernetes (`kubeadm`, `kubectl`, `kubelet`)

```bash
export KUBERNETES_VERSION=v1.32

curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

Nếu muốn đảm bảo `kubelet` nhận đúng IP node:

```bash
local_ip="$(ip -json addr show eth1 | jq -r '.[] | .addr_info[]? | select(.family=="inet") | .local')"
cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF
```

---

## 2. Khởi tạo Kubernetes trên `nodemaster`

### 📌 Cấu hình thông số cơ bản

```bash
CLUSTER_NAME="NDTCore Cluster"
CONTROL_IP_PREFIX="10.0.0."
CONTROL_IP_SUFFIX=10
CONTROL_IP="${CONTROL_IP_PREFIX}${CONTROL_IP_SUFFIX}"
DNS_SERVERS=("8.8.8.8" "1.1.1.1")
POD_CIDR="192.168.0.0/16"
SERVICE_CIDR="10.96.0.0/12"
NODENAME=$(hostname -s)
CONFIG_PATH="/vagrant/configs"
```

### 📌 Khởi tạo Control Plane

Chạy lệnh sau trên **nodemaster** để khởi tạo cluster Kubernetes:

```bash
sudo kubeadm init \
    --apiserver-advertise-address="$CONTROL_IP" \
    --apiserver-cert-extra-sans="$CONTROL_IP" \
    --pod-network-cidr="$POD_CIDR" \
    --service-cidr="$SERVICE_CIDR" \
    --node-name "$NODENAME" \
    --ignore-preflight-errors Swap
```

#### 🔍 Giải thích:

1️⃣ `sudo kubeadm init`

- Khởi tạo **Kubernetes control-plane node**.
- Thiết lập **API Server, Controller Manager, Scheduler** và các thành phần khác của control plane.
- Tạo file cấu hình `/etc/kubernetes/admin.conf`, chứa thông tin để giao tiếp với cluster.

2️⃣ `--apiserver-advertise-address="$CONTROL_IP"`

- Chỉ định địa chỉ IP mà API Server sẽ sử dụng để giao tiếp với các node khác.

3️⃣ `--apiserver-cert-extra-sans="$CONTROL_IP"`

- Thêm địa chỉ IP vào chứng chỉ TLS của API Server để đảm bảo kết nối bảo mật.

4️⃣ `--pod-network-cidr="$POD_CIDR"`

- Xác định **dải IP cho Pod Network**.
- Cần thiết để cấp **IP cho các Pod** trong cluster.
- Bắt buộc nếu sử dụng network plugin như **Calico, Flannel, Cilium**.

5️⃣ `--service-cidr="$SERVICE_CIDR"`

- Xác định **dải IP cho Kubernetes Services**.
- Các Service trong cluster sẽ sử dụng dải IP này.

6️⃣ `--node-name "$NODENAME"`

- Đặt tên cho node **control-plane**.

7️⃣ `--ignore-preflight-errors Swap`

- Bỏ qua lỗi nếu hệ thống chưa vô hiệu hóa Swap.

🔹 **Lưu ý:**

- Nếu sử dụng **Calico**, bạn có thể đặt `192.168.0.0/16` hoặc `10.244.0.0/16`.
- Nếu sử dụng **Flannel**, thường dùng `10.244.0.0/16`.
- Cần đảm bảo giá trị này **phù hợp với CNI plugin** bạn sẽ cài đặt sau đó.

---

### 📌 Thiết lập quyền sử dụng `kubectl`

Sau khi quá trình khởi tạo hoàn tất, cần cấp quyền cho `kubectl` hoạt động với cluster bằng cách:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

#### 🔍 Giải thích:

- `mkdir -p $HOME/.kube`: Tạo thư mục `.kube` trong thư mục home nếu chưa có.
- `sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config`: Sao chép file cấu hình cluster để `kubectl` có thể truy cập.
- `sudo chown $(id -u):$(id -g) $HOME/.kube/config`: Đặt quyền sở hữu file về user hiện tại để có thể sử dụng `kubectl` mà không cần quyền root.

---

### 📌 Lưu cấu hình vào thư mục dùng chung

Để các node worker có thể tham gia vào cluster, cần lưu lệnh `kubeadm join` và cấu hình vào thư mục chia sẻ (share):

```bash
sudo mkdir -p "$CONFIG_PATH"
sudo rm -f "$CONFIG_PATH/"*

sudo cp -i /etc/kubernetes/admin.conf "$CONFIG_PATH/config"
sudo kubeadm token create --print-join-command > "$CONFIG_PATH/join.sh"
sudo chmod +x "$CONFIG_PATH/join.sh"
```

#### 🔍 Giải thích:

- Sao chép file cấu hình của Kubernetes vào thư mục chia sẻ.
- Tạo lệnh `kubeadm join` để worker nodes có thể tham gia vào cluster.
- Đặt quyền thực thi cho file `join.sh`.

---

### 📌 Cấu hình mạng với Calico

[🔗 Giải thích chi tiết](05_configure_calico.md)

Sau khi khởi tạo cluster, cần cài đặt **Calico Network Plugin** để quản lý mạng giữa các Pod:

```bash
curl -fsSL "https://raw.githubusercontent.com/projectcalico/calico/master/manifests/calico.yaml" -o calico.yaml
kubectl apply -f calico.yaml
```

#### 🔍 Giải thích:

- **Calico** là một trong những **CNI plugin** phổ biến để quản lý mạng trong Kubernetes.
- Lệnh trên tải xuống file cấu hình của Calico và áp dụng vào cluster.

---

### 📌 Cấu hình `kubectl` cho user `vagrant`

Nếu bạn đang chạy Kubernetes trong môi trường Vagrant, cần cấp quyền `kubectl` cho user `vagrant`:

```bash
mkdir -p /home/vagrant/.kube
sudo cp -i "$CONFIG_PATH/config" /home/vagrant/.kube/config
sudo chown 1000:1000 /home/vagrant/.kube/config
```

#### 🔍 Giải thích:

- Sao chép cấu hình từ thư mục chia sẻ vào thư mục của user `vagrant`.
- Đặt quyền sở hữu để user `vagrant` có thể sử dụng `kubectl`.

---

### 📌 Cài đặt Metrics Server

Metrics Server cung cấp dữ liệu giám sát về tài nguyên sử dụng của Pod và Node trong cluster:

```bash
kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml
```

#### 🔍 Giải thích:

- **Metrics Server** thu thập thông tin về CPU, RAM của các Pod.
- Cần thiết cho các lệnh như `kubectl top nodes` và `kubectl top pods`.

---

### 📌 Kiểm tra trạng thái node

Sau khi thiết lập xong, kiểm tra trạng thái của node trong cluster:

```bash
kubectl get nodes
```

Kết quả mong đợi:

```bash
NAME         STATUS     ROLES           AGE     VERSION
nodemaster   Ready      control-plane   5m      v1.32.*
```

🚀 **Kubernetes đã được khởi tạo thành công trên `nodemaster`!**

---

## 3. Thêm Worker Node (`node01`) vào Cluster

Trên **nodemaster**, lấy lệnh `kubeadm join`:

```bash
kubeadm token create --print-join-command
```

Ví dụ:

```
kubeadm join 192.168.1.100:6443 --token abcdef.1234567890abcdef --discovery-token-ca-cert-hash sha256:<hash>
```

Sau đó, trên **node01**, chạy lệnh này:

```bash
sudo kubeadm join 192.168.1.100:6443 --token abcdef.1234567890abcdef --discovery-token-ca-cert-hash sha256:<hash>
```

---

## 4. Kiểm tra cluster

Trên **nodemaster**:

```bash
kubectl get nodes
```

Kết quả mong đợi:

```
NAME         STATUS   ROLES           AGE   VERSION
nodemaster   Ready    control-plane   10m   v1.31.0
node01       Ready    <none>          2m    v1.31.0
```

---

## 5. Chạy thử một ứng dụng

Trên **nodemaster**:

```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=NodePort --port=80
kubectl get svc
```

Truy cập:

```bash
http://<worker-node-ip>:<NodePort>
```

---

# 🎉 Kubernetes Cluster trên Vagrant đã sẵn sàng!

Bạn đã setup thành công Kubernetes trên Vagrant! 🚀
