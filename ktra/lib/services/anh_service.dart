import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

// Câu 2: chụp ảnh bằng camera và lưu cục bộ trong máy
class AnhService {
  final ImagePicker _picker = ImagePicker();

  Future<Directory> get _thuMuc async {
    final goc = await getApplicationDocumentsDirectory();
    final dir = Directory('${goc.path}/anh_sinh_vien');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<List<File>> _anhCua(String mssv) async {
    final dir = await _thuMuc;
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith('anh_${mssv}_'))
        .toList();
  }

  // Tên file có thời gian để Flutter không hiện lại ảnh cũ trong cache
  Future<File?> chupVaLuu(String mssv) async {
    final XFile? anh = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1000,
      imageQuality: 70,
    );
    if (anh == null) return null;

    final anhCu = await _anhCua(mssv);
    final dir = await _thuMuc;
    final ten = 'anh_${mssv}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = await File(anh.path).copy('${dir.path}/$ten');
    for (final f in anhCu) {
      await f.delete();
    }
    return file;
  }

  Future<File?> timAnhCucBo(String mssv) async {
    final ds = await _anhCua(mssv);
    return ds.isEmpty ? null : ds.first;
  }
}
