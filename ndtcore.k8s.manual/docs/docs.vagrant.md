# 📌 Lệnh Vagrant Cơ Bản

## 🎯 **Lệnh Cơ Bản**  
| Lệnh | Chức năng |
|------|----------|
| `vagrant init` | Tạo `Vagrantfile` mặc định trong thư mục hiện tại. |
| `vagrant up` | Khởi động và tạo VM theo `Vagrantfile`. |
| `vagrant halt` | Tắt máy ảo nhưng không xóa nó. |
| `vagrant reload` | Khởi động lại VM (áp dụng thay đổi từ `Vagrantfile`). |
| `vagrant destroy` | Xóa hoàn toàn VM đã tạo. |

---

## 🔍 **Kiểm Tra Trạng Thái**  
| Lệnh | Chức năng |
|------|----------|
| `vagrant status` | Kiểm tra trạng thái của VM. |
| `vagrant global-status` | Hiển thị trạng thái của tất cả VM đang chạy. |

---

## 🖥️ **Làm Việc Với Máy Ảo**  
| Lệnh | Chức năng |
|------|----------|
| `vagrant ssh <vm_name>` | SSH vào máy ảo (hoặc chỉ `vagrant ssh` nếu có 1 VM). |
| `vagrant suspend` | Tạm dừng VM (lưu trạng thái RAM để khởi động nhanh). |
| `vagrant resume` | Tiếp tục VM từ trạng thái `suspend`. |

---

## 🛠 **Cấu Hình và Debug**  
| Lệnh | Chức năng |
|------|----------|
| `vagrant provision` | Chạy lại các script provision mà không khởi động lại VM. |
| `vagrant reload --provision` | Khởi động lại VM và chạy lại provision. |
| `vagrant ssh-config` | Hiển thị thông tin SSH để kết nối thủ công. |
| `vagrant box list` | Xem danh sách các box đã tải về. |
| `vagrant box add <box_name>` | Thêm một box mới vào hệ thống. |
| `vagrant box remove <box_name>` | Xóa một box khỏi hệ thống. |

---

## 📦 **Quản Lý Plugin & Box**  
| Lệnh | Chức năng |
|------|----------|
| `vagrant plugin list` | Hiển thị danh sách plugin Vagrant đã cài. |
| `vagrant plugin install <plugin_name>` | Cài đặt một plugin Vagrant. |
| `vagrant box outdated` | Kiểm tra xem box có bản cập nhật không. |
| `vagrant box update` | Cập nhật box lên phiên bản mới nhất. |

---

## 💡 **Ví Dụ Cụ Thể**  
1️⃣ **Tạo VM và chạy**  
```bash
vagrant up
```

2️⃣ **SSH vào máy master**  
```bash
vagrant ssh node_master
```

3️⃣ **Dừng tất cả VM**  
```bash
vagrant halt
```

4️⃣ **Xóa tất cả VM đã tạo**  
```bash
vagrant destroy -f
```

5️⃣ **Khởi động lại tất cả VM và chạy lại provision**  
```bash
vagrant reload --provision
```

