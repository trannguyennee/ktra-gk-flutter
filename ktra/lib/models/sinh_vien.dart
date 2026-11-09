class SinhVien {
  String mssv;
  String hoTen;
  bool coAnh;

  SinhVien({required this.mssv, required this.hoTen, this.coAnh = false});

  factory SinhVien.fromJson(Map<String, dynamic> json) {
    return SinhVien(
      mssv: json['mssv'],
      hoTen: json['hoTen'],
      coAnh: json['coAnh'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'mssv': mssv, 'hoTen': hoTen};
  }
}

// 2 thành viên của nhóm hiển thị ở trang 1
final List<SinhVien> nhomSinhVien = [
  SinhVien(mssv: '1250080121', hoTen: 'Trần Nguyên'),
  SinhVien(mssv: '1250080166', hoTen: 'Hoàng Đình Tân'),
];
