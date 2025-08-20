# 💲 Debt Manager App  

Ứng dụng quản lý nợ cá nhân viết bằng **Flutter**.  
Cho phép lưu, chỉnh sửa, xóa và theo dõi các khoản nợ.  

---

## ✨ Tính năng  

- ➕ **Thêm nợ mới**: nhập người nợ, số tiền, ngày vay, ngày trả  
- 🖼️ **Đính kèm ảnh hóa đơn** từ thư viện ảnh  
- ✏️ **Sửa khoản nợ** với dialog trực quan  
- ✅ **Đánh dấu đã trả nợ**  
- 🗑️ **Xóa khoản nợ**  
- 🌙 **Đa dạng giao diện**: Light, Dark, OLED  
- 🎨 **Tùy chọn màu chủ đạo**  
- 💾 **Lưu dữ liệu cục bộ** bằng `SharedPreferences`  

---

## 📸 Giao diện  

- Danh sách nợ với icon 💲  
- Xem ảnh hóa đơn bằng cách nhấn vào mục nợ  
- SnackBar thông báo đồng bộ (thêm / sửa / xóa giống hệ thống)  

---

## 🛠️ Cài đặt  

1. Clone repo về máy:  
   ```bash
   git clone https://github.com/<username>/<repo>.git
   cd <repo>


2. Cài dependencies:

   ```bash
   flutter pub get
   ```

3. Chạy ứng dụng:

   ```bash
   flutter run
   ```

---

## 📂 Cấu trúc chính

```
lib/
 ├── main.dart            # Điểm khởi động ứng dụng
 ├── models/debt.dart     # Model khoản nợ
 ├── widgets/             # Các widget (Dialog sửa, chọn theme...)
 └── ...
```

---

## 📦 Dependencies

* `intl` – định dạng ngày tháng
* `shared_preferences` – lưu dữ liệu cục bộ
* `image_picker` – chọn ảnh hóa đơn

---

## 🚀 Định hướng phát triển

* 📊 Thống kê tổng nợ / đã trả
* 🔔 Thêm thông báo nhắc trả nợ
* ☁️ Đồng bộ dữ liệu với Firebase/Cloud

---

## 👨‍💻 Tác giả

* Nguyễn Minh Duy
* 📧 Email: [ngduy10102006@gmail.com](mailto:ngduy10102006@gmail.com)



