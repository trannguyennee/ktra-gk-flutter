-- Tạo CSDL cho bài KT-GK Flutter
IF DB_ID(N'KtraFlutter') IS NULL
    CREATE DATABASE KtraFlutter;
GO
USE KtraFlutter;
GO
IF OBJECT_ID(N'dbo.SinhVien') IS NULL
CREATE TABLE dbo.SinhVien (
    MSSV  NVARCHAR(20)   NOT NULL PRIMARY KEY,
    HoTen NVARCHAR(100)  NOT NULL,
    Anh   VARBINARY(MAX) NULL      -- ảnh chụp từ camera (câu 2)
);
GO
IF OBJECT_ID(N'dbo.MonHoc') IS NULL
CREATE TABLE dbo.MonHoc (
    MaMon  NVARCHAR(20)  NOT NULL PRIMARY KEY,
    TenMon NVARCHAR(200) NOT NULL,
    CoSo   NVARCHAR(50)  NOT NULL, -- Nhà Bè / Lê Văn Sỹ
    GioHoc DATETIME2     NULL      -- giờ thông báo (câu 5)
);
GO
-- 2 thành viên nhóm
IF NOT EXISTS (SELECT 1 FROM dbo.SinhVien WHERE MSSV = N'1250080121')
    INSERT dbo.SinhVien (MSSV, HoTen) VALUES (N'1250080121', N'Trần Nguyên');
IF NOT EXISTS (SELECT 1 FROM dbo.SinhVien WHERE MSSV = N'1250080166')
    INSERT dbo.SinhVien (MSSV, HoTen) VALUES (N'1250080166', N'Hoàng Đình Tân');
GO
