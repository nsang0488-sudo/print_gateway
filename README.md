# POS Web App

Ứng dụng web POS bán hàng chuyên nghiệp, hỗ trợ đa cửa hàng và đồng bộ dữ liệu Realtime Database với Firebase.

## Cấu hình Firebase Realtime Database Rules

Để ứng dụng đọc/ghi dữ liệu cửa hàng và hệ thống trơn tru (tránh lỗi `permission_denied` / `401 Unauthorized`), bạn cần bật phân quyền Realtime Database trong Firebase Console:

1. Truy cập [Firebase Console](https://console.firebase.google.com/) -> Chọn Project `fir-pos-8ff24`.
2. Vào mục **Build** -> **Realtime Database** -> Tab **Rules**.
3. Cập nhật nội dung Rules như sau rồi bấm **Publish**:

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

## Cài đặt & Chạy ứng dụng

Mở file `index.html` trực tiếp trên trình duyệt hoặc chạy qua bất kỳ static web server nào:

```bash
# Ví dụ chạy bằng Python HTTP server
python3 -m http.server 8080

# Hoặc bằng npx serve
npx serve .
```
