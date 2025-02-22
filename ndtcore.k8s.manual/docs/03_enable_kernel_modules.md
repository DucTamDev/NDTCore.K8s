# Cấu hình Kernel Modules cho Kubernetes

## Tại sao cần cấu hình Kernel Modules?

Kubernetes yêu cầu một số kernel modules nhất định để hỗ trợ networking và quản lý container. Việc bật các modules này giúp đảm bảo Kubernetes hoạt động ổn định và tối ưu hiệu suất.

### Các module quan trọng:

- **overlay**: Hỗ trợ hệ thống tệp overlayfs, được sử dụng bởi container runtime như Docker và CRI-O.
- **br_netfilter**: Cho phép Kubernetes kiểm soát traffic mạng bằng cách sử dụng iptables và xử lý cầu nối mạng.

## Cách cấu hình Kernel Modules

### 1. Tải các module cần thiết

Chạy các lệnh sau để tải ngay lập tức các module:

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

### 2. Cấu hình để tự động tải module khi khởi động lại

Tạo file cấu hình `/etc/modules-load.d/k8s.conf` để đảm bảo các module này được nạp mỗi lần hệ thống khởi động:

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```

### 3. Cấu hình sysctl để hỗ trợ networking

Tạo file `/etc/sysctl.d/k8s.conf` với các thông số cần thiết để đảm bảo networking hoạt động chính xác:

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
```

### 4. Áp dụng thay đổi sysctl

Sau khi cấu hình, áp dụng thay đổi ngay lập tức bằng lệnh:

```bash
sudo sysctl --system
```

Sau khi hoàn thành bước này, hệ thống sẽ được chuẩn bị sẵn sàng để chạy Kubernetes với đầy đủ hỗ trợ networking và container runtime.
