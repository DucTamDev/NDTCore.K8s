# Tắt Swap trong Kubernetes

## Tại sao cần tắt Swap?
Kubernetes yêu cầu swap phải bị tắt trên tất cả các node vì:
- **Quản lý tài nguyên hiệu quả hơn**: Kubelet hoạt động tốt nhất khi có thể dự đoán lượng tài nguyên khả dụng mà không bị ảnh hưởng bởi việc hoán đổi bộ nhớ.
- **Tránh ảnh hưởng đến hiệu suất**: Nếu một node sử dụng swap, hiệu suất của các Pod có thể bị ảnh hưởng do thời gian truy cập bộ nhớ chậm hơn.
- **Kubelet có thể không hoạt động đúng**: Nếu swap không bị vô hiệu hóa, kubeadm có thể báo lỗi khi khởi tạo cluster.

## Cách tắt Swap

### 1. Vô hiệu hóa Swap ngay lập tức
Chạy lệnh sau để tắt swap ngay lập tức:
```bash
sudo swapoff -a
```

### 2. Ngăn swap tự động bật lại sau khi reboot
Để đảm bảo swap không tự động kích hoạt khi hệ thống khởi động lại, hãy chỉnh sửa file `/etc/fstab`:
```bash
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```
Lệnh trên sẽ comment dòng cấu hình swap trong `/etc/fstab`, ngăn hệ thống bật lại swap khi khởi động.

### 3. Đảm bảo swap luôn tắt sau khi reboot
Thêm lệnh vào crontab để tắt swap mỗi khi hệ thống khởi động:
```bash
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
```

Sau khi hoàn thành bước này, swap sẽ bị vô hiệu hóa hoàn toàn và Kubernetes có thể hoạt động ổn định hơn.

