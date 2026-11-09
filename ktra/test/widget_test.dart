import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ktra/controllers/ban_do_controller.dart';
import 'package:ktra/models/mon_hoc.dart';
import 'package:ktra/models/sinh_vien.dart';
import 'package:ktra/services/pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Giải mã polyline', () {
    final p = BanDoController.giaiMaPolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    expect(p.length, 3);
    expect(p.first.latitude, closeTo(38.5, 1e-6));
    expect(p.last.longitude, closeTo(-126.453, 1e-6));
  });

  test('Id thông báo cố định và nằm trong int32', () {
    final a = MonHoc(maMon: 'LTDD01', tenMon: 'x', coSo: 'Nhà Bè');
    final b = MonHoc(maMon: 'LTDD01', tenMon: 'y', coSo: 'Lê Văn Sỹ');
    expect(a.idThongBao, b.idThongBao);
    expect(a.idThongBao, lessThanOrEqualTo(0x7fffffff));
  });

  test('Xuất PDF tiếng Việt', () async {
    final bytes = await PdfService().taoPdf([
      SinhVien(mssv: '1250080121', hoTen: 'Trần Nguyên'),
    ], <String, Uint8List>{});
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    File('build/test_ds.pdf')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
  });
}
