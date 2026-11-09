# KT-GK Flutter

Bài kiểm tra giữa kỳ môn Lập trình ứng dụng di động. Khoa CNTT, ĐH Tài nguyên & Môi trường TP.HCM.

- 1250080121 - Trần Nguyên
- 1250080166 - Hoàng Đình Tân

## Cấu trúc

| Thư mục | Nội dung |
|---|---|
| `ktra` | App Flutter theo mô hình MVC |
| `ktra_api` | API ASP.NET Core kết nối SQL Server |
| `ktra_api/database.sql` | Script tạo database `KtraFlutter` |

## Cần cài

Flutter, Android SDK 37, .NET 9, SQL Server và SSMS.

## Cách chạy

1. Mở `ktra_api/database.sql` trong SSMS rồi bấm **Execute** để tạo database.
2. Nếu SQL Server không phải bản mặc định, sửa `Server=localhost` trong `ktra_api/appsettings.json` (ví dụ `Server=localhost\\SQLEXPRESS`).
3. Chạy API, lần đầu Windows hỏi tường lửa thì chọn **Allow**:

   ```bash
   cd ktra_api
   dotnet run
   ```

4. Cắm điện thoại vào máy tính rồi chạy app:

   ```bash
   cd ktra
   flutter pub get
   flutter run
   ```

5. Cho điện thoại và máy tính dùng chung Wi-Fi. Xem IPv4 của Wi-Fi bằng `ipconfig`, rồi trong app bấm chữ **Mất kết nối** ở góc phải và nhập địa chỉ, ví dụ `http://192.168.1.10:5000`.

Nhớ bật GPS, cấp quyền vị trí, thông báo và báo thức khi điện thoại hỏi.
