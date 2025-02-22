# Cấu hình Calico cho Kubernetes

## Tại sao cần cấu hình Calico?

Calico là một giải pháp mạng và bảo mật dành cho Kubernetes, giúp quản lý kết nối giữa các Pod. Việc cài đặt Calico giúp:

- Cung cấp mạng cho các Pod (Pod-to-Pod networking).
- Hỗ trợ chính sách mạng (Network Policies) để kiểm soát luồng dữ liệu giữa các Pod.
- Cải thiện hiệu suất với mô hình điều hướng tối ưu.

## Cách triển khai Calico

Chạy lệnh sau trên **nodemaster** để áp dụng cấu hình Calico:

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml
```

### Kiểm tra trạng thái của Calico

Sau khi cài đặt, kiểm tra các Pod của Calico để đảm bảo chúng đang chạy:

```bash
kubectl get pods -n calico-system
```

Kết quả mong đợi:

```
NAME                                       READY   STATUS    RESTARTS   AGE
calico-kube-controllers-xxxxxxx            1/1     Running   0          1m
calico-node-xxxxx                          1/1     Running   0          1m
calico-typha-xxxxxxx                       1/1     Running   0          1m
```

Nếu tất cả các Pod trong namespace `calico-system` đều ở trạng thái `Running`, nghĩa là Calico đã được cài đặt thành công và mạng đã hoạt động.
