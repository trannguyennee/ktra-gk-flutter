import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/mon_hoc_controller.dart';
import '../services/api_service.dart';
import 'danh_sach_view.dart';
import 'mon_hoc_view.dart';
import 'thong_tin_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final GlobalKey<DanhSachViewState> danhSachKey = GlobalKey();
  final ApiService api = ApiService();
  int trang = 0;
  // chỉ tạo trang khi mở lần đầu, để app không xin quyền vị trí ngay lúc khởi động
  final Set<int> trangDaMo = {0};

  bool? daKetNoi;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    kiemTraServer();
    // vừa bật Wi-Fi hoặc mở API là app tự kết nối lại
    timer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => kiemTraServer(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> kiemTraServer() async {
    final ok = await api.kiemTraKetNoi();
    if (!mounted || ok == daKetNoi) return;
    setState(() => daKetNoi = ok);
    if (ok) {
      MonHocController().dongBoNhacGio();
      danhSachKey.currentState?.taiLai();
    }
  }

  // Đổi Wi-Fi thì IP máy tính đổi theo, nhập lại ở đây
  void moCaiDat() async {
    final textController = TextEditingController(text: ApiService.baseUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Địa chỉ API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              daKetNoi == true
                  ? 'Đang kết nối tốt với API.'
                  : 'Chưa kết nối được. Hãy bật Wi-Fi, dùng chung mạng với laptop và kiểm tra địa chỉ dưới đây.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.5:5000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (url == null || url.trim().isEmpty) return;

    await ApiService.luuCauHinh(url);
    await kiemTraServer();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          daKetNoi == true
              ? 'Đã kết nối API'
              : 'Chưa kết nối được ${ApiService.baseUrl}',
        ),
      ),
    );
  }

  void doiTrang(int i) {
    setState(() {
      trang = i;
      trangDaMo.add(i);
    });
    if (i == 2) danhSachKey.currentState?.taiLai();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // bàn phím che bản đồ thay vì ép bản đồ co lại
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(const ['KT-GK Flutter', 'Môn học', 'Sinh viên'][trang]),
        actions: [
          TextButton.icon(
            onPressed: moCaiDat,
            icon: Icon(
              daKetNoi == true ? Icons.cloud_done : Icons.cloud_off,
              size: 20,
              color: daKetNoi == true ? Colors.green : Colors.redAccent,
            ),
            label: Text(
              daKetNoi == true ? 'Đã kết nối' : 'Mất kết nối',
              style: TextStyle(
                fontSize: 13,
                color: daKetNoi == true ? Colors.green : Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: trang,
        children: [
          const ThongTinView(),
          trangDaMo.contains(1) ? const MonHocView() : const SizedBox.shrink(),
          trangDaMo.contains(2)
              ? DanhSachView(key: danhSachKey)
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: trang,
        onDestinationSelected: doiTrang,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.badge), label: 'Thông tin'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Môn học'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Sinh viên'),
        ],
      ),
    );
  }
}
