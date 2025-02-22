# Cài đặt Các Gói Phụ Thuộc Cho Kubernetes

## Tại sao cần cài đặt các gói phụ thuộc?

Kubernetes yêu cầu một số công cụ và thư viện hệ thống để hoạt động ổn định. Việc cài đặt đầy đủ các gói phụ thuộc giúp đảm bảo quá trình thiết lập Kubernetes diễn ra suôn sẻ.

## Cách cài đặt các gói phụ thuộc

### 1. Cập nhật danh sách package

Trước khi cài đặt, cần cập nhật danh sách package để đảm bảo phiên bản mới nhất:

```bash
sudo apt-get update -y
```

### 2. Cài đặt các gói cần thiết

Cài đặt các gói phụ thuộc quan trọng cho Kubernetes:

```bash
sudo apt-get install -y \
    software-properties-common \
    curl \
    apt-transport-https \
    ca-certificates \
    jq
```

#### Giải thích từng gói:

- **software-properties-common**: Hỗ trợ quản lý các repository phần mềm bổ sung.
- **curl**: Công cụ giúp tải dữ liệu từ các nguồn bên ngoài (ví dụ: tải file cài đặt Kubernetes).
- **apt-transport-https**: Hỗ trợ APT làm việc với giao thức HTTPS để tải package an toàn hơn.
- **ca-certificates**: Cung cấp chứng chỉ SSL/TLS để đảm bảo các kết nối bảo mật.
- **jq**: Công cụ xử lý JSON, hỗ trợ quản lý cấu hình hệ thống và Kubernetes.

Sau khi hoàn thành bước này, hệ thống của bạn sẽ sẵn sàng để tiếp tục cài đặt các thành phần Kubernetes.
