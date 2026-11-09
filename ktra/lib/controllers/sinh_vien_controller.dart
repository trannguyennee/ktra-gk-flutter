import 'dart:io';
import 'dart:typed_data';
import '../models/sinh_vien.dart';
import '../services/anh_service.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';

class SinhVienController {
  final ApiService _api = ApiService();
  final AnhService _anh = AnhService();
  final PdfService _pdf = PdfService();

  Future<List<SinhVien>> layDanhSach() => _api.layDanhSachSinhVien();

  Future<File?> timAnhCucBo(String mssv) => _anh.timAnhCucBo(mssv);

  String urlAnh(String mssv) => _api.urlAnh(mssv);

  // Câu 2 + 3: chụp, lưu cục bộ. Đẩy lên SQL Server gọi riêng để vẫn giữ được ảnh khi mất mạng
  Future<File?> chupAnh(String mssv) => _anh.chupVaLuu(mssv);

  Future<void> guiAnhLenServer(String mssv, File file) async {
    await _api.capNhatAnh(mssv, await file.readAsBytes());
  }

  Future<({int them, int trung})> nhapDanhSach(List<SinhVien> ds) {
    return _api.nhapSinhVien(ds);
  }

  Future<void> xoa(String mssv) => _api.xoaSinhVien(mssv);

  // Câu 6: lấy danh sách hiện tại từ SQL Server, tạo PDF rồi lưu vào điện thoại
  Future<bool> xuatPdf() async {
    final ds = await _api.layDanhSachSinhVien();
    final anh = <String, Uint8List>{};
    for (final sv in ds.where((e) => e.coAnh)) {
      final bytes = await _api.taiAnh(sv.mssv);
      if (bytes != null) anh[sv.mssv] = bytes;
    }
    return _pdf.luuVaoDienThoai(await _pdf.taoPdf(ds, anh));
  }
}
