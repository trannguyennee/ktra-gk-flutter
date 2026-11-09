import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/sinh_vien.dart';

// Câu 6: xuất PDF danh sách sinh viên
class PdfService {
  Future<Uint8List> taoPdf(
    List<SinhVien> ds,
    Map<String, Uint8List> anh,
  ) async {
    // font Roboto có đủ dấu tiếng Việt, font mặc định của PDF thì không
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/roboto-regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/roboto-bold.ttf'),
    );
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    pw.Widget o(String text, {bool dam = false}) => pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: dam ? pw.FontWeight.bold : null),
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Center(child: pw.Text('ĐH TÀI NGUYÊN & MÔI TRƯỜNG TPHCM')),
          pw.Center(child: pw.Text('Khoa CNTT')),
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.Text(
              'DANH SÁCH SINH VIÊN',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Center(
            child: pw.Text(
              'Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'
              ' - Tổng số: ${ds.length} sinh viên',
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: const {
              0: pw.FixedColumnWidth(40),
              1: pw.FixedColumnWidth(110),
              2: pw.FlexColumnWidth(),
              3: pw.FixedColumnWidth(70),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  o('STT', dam: true),
                  o('MSSV', dam: true),
                  o('Họ tên', dam: true),
                  o('Ảnh', dam: true),
                ],
              ),
              for (var i = 0; i < ds.length; i++)
                pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    o('${i + 1}'),
                    o(ds[i].mssv),
                    o(ds[i].hoTen),
                    anh[ds[i].mssv] == null
                        ? o('')
                        : pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Image(
                              pw.MemoryImage(anh[ds[i].mssv]!),
                              height: 50,
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  // Mở hộp thoại lưu của Android để chọn thư mục trên điện thoại (Download...)
  // Trả về false nếu người dùng bấm hủy
  Future<bool> luuVaoDienThoai(Uint8List bytes) async {
    final gio = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final uri = await FilePicker.saveFile(
      dialogTitle: 'Lưu danh sách sinh viên',
      fileName: 'danh_sach_sinh_vien_$gio.pdf',
      bytes: bytes,
    );
    return uri != null;
  }
}
