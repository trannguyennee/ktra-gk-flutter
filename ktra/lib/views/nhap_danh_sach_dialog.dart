import 'package:flutter/material.dart';
import '../models/sinh_vien.dart';

// Câu 6: nhập từng sinh viên vào danh sách tạm, rồi lưu cả danh sách
class NhapDanhSachDialog extends StatefulWidget {
  const NhapDanhSachDialog({super.key});

  @override
  State<NhapDanhSachDialog> createState() => _NhapDanhSachDialogState();
}

class _NhapDanhSachDialogState extends State<NhapDanhSachDialog> {
  final TextEditingController mssvController = TextEditingController();
  final TextEditingController hoTenController = TextEditingController();
  final FocusNode mssvFocus = FocusNode();
  final List<SinhVien> ds = [];
  String? loi;

  @override
  void dispose() {
    mssvController.dispose();
    hoTenController.dispose();
    mssvFocus.dispose();
    super.dispose();
  }

  // Trả về true nếu đã thêm được
  bool them() {
    final mssv = mssvController.text.trim();
    final hoTen = hoTenController.text.trim();

    if (mssv.isEmpty || hoTen.isEmpty) {
      setState(() => loi = 'Hãy nhập đủ MSSV và họ tên');
      return false;
    }
    if (ds.any((e) => e.mssv == mssv)) {
      setState(() => loi = 'MSSV $mssv đã có trong danh sách này');
      return false;
    }

    setState(() {
      ds.add(SinhVien(mssv: mssv, hoTen: hoTen));
      loi = null;
    });
    mssvController.clear();
    hoTenController.clear();
    mssvFocus.requestFocus();
    return true;
  }

  void luu() {
    // đang nhập dở người cuối thì tự thêm luôn
    final dangNhap =
        mssvController.text.trim().isNotEmpty ||
        hoTenController.text.trim().isNotEmpty;
    if (dangNhap && !them()) return;

    if (ds.isEmpty) {
      setState(() => loi = 'Danh sách đang trống');
      return;
    }
    Navigator.pop(context, ds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nhập danh sách sinh viên'),
      scrollable: true,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: mssvController,
              focusNode: mssvFocus,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'MSSV',
                prefixIcon: Icon(Icons.badge_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: hoTenController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => them(),
              decoration: const InputDecoration(
                labelText: 'Họ tên',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
            ),
            if (loi != null) ...[
              const SizedBox(height: 8),
              Text(loi!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: them,
              icon: const Icon(Icons.add),
              label: const Text('Thêm vào danh sách'),
            ),
            if (ds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Sẽ lưu ${ds.length} sinh viên:',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              for (final sv in ds)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(sv.hoTen),
                  subtitle: Text(sv.mssv),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => ds.remove(sv)),
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: luu, child: const Text('Lưu vào SQL')),
      ],
    );
  }
}
