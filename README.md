# KT-GK Flutter

Bài kiểm tra giữa kỳ môn Lập trình ứng dụng di động. Khoa CNTT, ĐH Tài nguyên & Môi trường TP.HCM.

- 1250080121 - Trần Nguyên
- 1250080166 - Hoàng Đình Tân

## Cấu trúc

| Thư mục | Nội dung |
|---|---|
| `ktra` | App Flutter theo mô hình MVC |
| `ktra_api_express` | API Express (Node.js) kết nối SQL Server |
| `ktra_api_express/database.sql` | Script tạo database `KtraFlutter` |

## Cần cài

Flutter, Android SDK 37, Node.js (bản LTS), SQL Server và SSMS.

## Cách chạy

1. Mở `ktra_api_express/database.sql` trong SSMS rồi bấm **Execute** để tạo database.
2. Nếu SQL Server không phải bản mặc định, sửa `"server"` trong `ktra_api_express/config.json` (ví dụ `"localhost\\SQLEXPRESS"`).
3. Chạy API, lần đầu Windows hỏi tường lửa thì chọn **Allow**:

   ```bash
   cd ktra_api_express
   npm install
   npm start
   ```

4. Cắm điện thoại vào máy tính rồi chạy app:

   ```bash
   cd ktra
   flutter pub get
   flutter run
   ```

5. Cho điện thoại và máy tính dùng chung Wi-Fi. Xem IPv4 của Wi-Fi bằng `ipconfig`, rồi trong app bấm chữ **Mất kết nối** ở góc phải và nhập địa chỉ, ví dụ `http://192.168.1.10:5000`.

Nhớ bật GPS, cấp quyền vị trí, thông báo và báo thức khi điện thoại hỏi.
