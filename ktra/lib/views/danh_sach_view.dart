import 'package:flutter/material.dart';
import '../controllers/sinh_vien_controller.dart';
import '../models/sinh_vien.dart';
import 'nhap_danh_sach_dialog.dart';

// Câu 6: nhập danh sách sinh viên vào SQL Server và xuất PDF
class DanhSachView extends StatefulWidget {
  const DanhSachView({super.key});

  @override
  State<DanhSachView> createState() => DanhSachViewState();
}

class DanhSachViewState extends State<DanhSachView> {
  final SinhVienController controller = SinhVienController();
  List<SinhVien> ds = [];
  String? loi;
  bool dangTai = true;
  bool dangXuat = false;
  int phienBanAnh = 0; // đổi để tải lại ảnh mới nhất

  @override
  void initState() {
    super.initState();
    taiLai();
  }

  Future<void> taiLai() async {
    try {
      final kq = await controller.layDanhSach();
      if (!mounted) return;
      setState(() {
        ds = kq;
        loi = null;
        dangTai = false;
        phienBanAnh++;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          loi = '$e';
          dangTai = false;
        });
      }
    }
  }

  void thongBao(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void moNhapDanhSach() async {
    final dsMoi = await showDialog<List<SinhVien>>(
      context: context,
      builder: (_) => const NhapDanhSachDialog(),
    );
    if (dsMoi == null) return;

    try {
      final kq = await controller.nhapDanhSach(dsMoi);
      thongBao('Đã thêm ${kq.them} sinh viên, bỏ qua ${kq.trung} MSSV trùng');
      await taiLai();
    } catch (e) {
      thongBao('$e');
    }
  }

  void xoa(SinhVien sv) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sinh viên'),
        content: Text('Xóa ${sv.mssv} - ${sv.hoTen} khỏi SQL Server?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (dongY != true) return;

    try {
      await controller.xoa(sv.mssv);
      await taiLai();
    } catch (e) {
      thongBao('$e');
    }
  }

  void xuatPdf() async {
    setState(() => dangXuat = true);
    try {
      final daLuu = await controller.xuatPdf();
      if (daLuu && mounted) thongBao('Đã lưu file PDF vào điện thoại');
    } catch (e) {
      if (mounted) thongBao('Chưa xuất được PDF: $e');
    }
    if (mounted) setState(() => dangXuat = false);
  }

  Widget noiDung() {
    if (dangTai) return const Center(child: CircularProgressIndicator());

    if (loi != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(loi!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () {
                setState(() => dangTai = true);
                taiLai();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (ds.isEmpty) {
      return const Center(child: Text('Chưa có sinh viên nào'));
    }

    return RefreshIndicator(
      onRefresh: taiLai,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: ds.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final sv = ds[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFD5E5FA),
                foregroundImage: sv.coAnh
                    ? NetworkImage(
                        '${controller.urlAnh(sv.mssv)}?v=$phienBanAnh',
                      )
                    : null,
                child: Text('${index + 1}'),
              ),
              title: Text(
                sv.hoTen,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('MSSV: ${sv.mssv}'),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                onPressed: () => xoa(sv),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: moNhapDanhSach,
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Nhập DS'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: dangXuat ? null : xuatPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(dangXuat ? 'Đang xuất...' : 'Xuất PDF'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: noiDung()),
        ],
      ),
    );
  }
}
