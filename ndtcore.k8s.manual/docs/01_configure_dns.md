# Cấu hình DNS cho Kubernetes

## Tại sao cần cấu hình DNS?

DNS (Domain Name System) giúp chuyển đổi tên miền thành địa chỉ IP, đóng vai trò quan trọng trong việc định tuyến và kết nối giữa các thành phần trong Kubernetes.

### Lợi ích của việc cấu hình DNS:
- Đảm bảo các node trong cluster có thể phân giải địa chỉ chính xác.
- Hỗ trợ Kubernetes trong việc tìm kiếm dịch vụ nội bộ thông qua DNS-based service discovery.
- Tránh lỗi kết nối khi các Pod hoặc Service cần giao tiếp với nhau bằng tên miền.

## Cách cấu hình DNS

### 1. Tạo thư mục cấu hình DNS
Systemd-resolved là một dịch vụ quản lý DNS trên hệ điều hành Linux. Ta cần tạo thư mục chứa file cấu hình cho dịch vụ này:
```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
```

### 2. Thiết lập DNS Servers
Khi cấu hình Kubernetes, ta có thể chỉ định danh sách máy chủ DNS (ví dụ: Google DNS hoặc Cloudflare DNS) để đảm bảo hệ thống có thể phân giải tên miền.
```bash
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dns_servers.conf
[Resolve]
DNS=${DNS_SERVERS}
EOF
```
- `${DNS_SERVERS}` là danh sách các máy chủ DNS bạn muốn sử dụng (ví dụ: 8.8.8.8, 1.1.1.1).

### 3. Khởi động lại dịch vụ DNS
Sau khi thiết lập DNS, cần khởi động lại systemd-resolved để áp dụng cấu hình mới.
```bash
sudo systemctl restart systemd-resolved
```

Sau khi hoàn thành bước này, hệ thống sẽ sử dụng các máy chủ DNS do bạn chỉ định, giúp Kubernetes có thể phân giải tên miền chính xác và hoạt động ổn định hơn.

