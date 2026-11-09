import 'dart:io';
import 'package:flutter/material.dart';
import '../controllers/sinh_vien_controller.dart';
import '../models/sinh_vien.dart';

const Color _xanhDam = Color(0xFF1565C0);

// Trang 1: thông tin nhóm và ảnh chụp từ camera
class ThongTinView extends StatefulWidget {
  const ThongTinView({super.key});

  @override
  State<ThongTinView> createState() => _ThongTinViewState();
}

class _ThongTinViewState extends State<ThongTinView> {
  final SinhVienController controller = SinhVienController();
  final Map<String, File> anhCucBo = {};
  final Map<String, String> trangThaiAnh = {};
  SinhVien dangChon = nhomSinhVien.first;
  bool dangGui = false;

  @override
  void initState() {
    super.initState();
    taiAnhCucBo();
  }

  void taiAnhCucBo() async {
    for (final sv in nhomSinhVien) {
      final file = await controller.timAnhCucBo(sv.mssv);
      if (file != null) anhCucBo[sv.mssv] = file;
    }
    if (mounted) setState(() {});
  }

  // chụp -> lưu cục bộ -> hiện lên -> đẩy vào SQL Server
  void chupAnh() async {
    final sv = dangChon;
    final file = await controller.chupAnh(sv.mssv);
    if (file == null || !mounted) return;

    setState(() {
      anhCucBo[sv.mssv] = file;
      trangThaiAnh[sv.mssv] = 'Đang gửi ảnh lên SQL Server...';
      dangGui = true;
    });

    String ketQua;
    try {
      await controller.guiAnhLenServer(sv.mssv, file);
      ketQua = 'Đã lưu trong máy và SQL Server';
    } catch (e) {
      ketQua = 'Đã lưu trong máy, chưa lên SQL Server: $e';
    }
    if (!mounted) return;
    setState(() {
      trangThaiAnh[sv.mssv] = ketQua;
      dangGui = false;
    });
  }

  Widget phanDau() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ĐH TÀI NGUYÊN & MÔI TRƯỜNG TPHCM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Khoa CNTT',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [nhanNho('KT-GK'), nhanNho('Flutter')],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget nhanNho(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget theSinhVien(SinhVien sv) {
    final chon = sv.mssv == dangChon.mssv;
    final file = anhCucBo[sv.mssv];
    return InkWell(
      onTap: () => setState(() => dangChon = sv),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: chon ? const Color(0xFFE3F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: chon ? _xanhDam : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFD5E5FA),
              foregroundImage: file == null ? null : FileImage(file),
              child: Text(
                sv.hoTen.split(' ').last[0],
                style: const TextStyle(
                  color: _xanhDam,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sv.hoTen,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'MSSV: ${sv.mssv}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              chon ? Icons.check_circle : Icons.circle_outlined,
              color: chon ? _xanhDam : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget nenChuaCoAnh() {
    return Container(
      color: const Color(0xFFEAF2FD),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: _xanhDam,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_camera,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Chạm để chụp ảnh',
            style: TextStyle(
              color: _xanhDam,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget khungAnh() {
    final file = anhCucBo[dangChon.mssv];
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        height: 260,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // luôn có nền phía dưới để lúc đang tải ảnh không bị khung trắng
            nenChuaCoAnh(),
            if (file != null)
              Image.file(file, fit: BoxFit.cover)
            else
              Image.network(
                controller.urlAnh(dangChon.mssv),
                key: ValueKey(dangChon.mssv),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            if (dangGui)
              Container(
                color: Colors.black38,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: dangGui ? null : chupAnh),
              ),
            ),
            if (file != null)
              Positioned(
                right: 12,
                bottom: 12,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Chụp lại',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trangThai = trangThaiAnh[dangChon.mssv];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          phanDau(),
          const SizedBox(height: 18),
          const Text(
            'Thành viên nhóm',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final sv in nhomSinhVien) ...[
            theSinhVien(sv),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          Text(
            'Ảnh của ${dangChon.hoTen}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          khungAnh(),
          if (trangThai != null) ...[
            const SizedBox(height: 8),
            Text(
              trangThai,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
