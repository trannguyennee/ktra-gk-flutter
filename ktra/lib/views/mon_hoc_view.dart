import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/mon_hoc_controller.dart';
import '../models/co_so.dart';
import '../models/mon_hoc.dart';
import 'ban_do_view.dart';

// Trang 2: môn học, cơ sở, giờ học và bản đồ
class MonHocView extends StatefulWidget {
  const MonHocView({super.key});

  @override
  State<MonHocView> createState() => _MonHocViewState();
}

class _MonHocViewState extends State<MonHocView> {
  final MonHocController controller = MonHocController();
  final TextEditingController maMonController = TextEditingController();
  final TextEditingController tenMonController = TextEditingController();
  CoSo coSo = dsCoSo.first;
  DateTime? gioHoc;
  bool dangLuu = false;

  void thongBao(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // CHỌN NGÀY + GIỜ
  void chonGioHoc() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      gioHoc = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void luu() async {
    if (maMonController.text.trim().isEmpty ||
        tenMonController.text.trim().isEmpty) {
      thongBao('Hãy nhập mã môn và tên môn');
      return;
    }

    setState(() => dangLuu = true);
    try {
      final kq = await controller.luu(
        MonHoc(
          maMon: maMonController.text.trim(),
          tenMon: tenMonController.text.trim(),
          coSo: coSo.ten,
          gioHoc: gioHoc,
        ),
      );
      if (mounted) thongBao(kq);
    } catch (e) {
      if (mounted) thongBao('Chưa lưu được vào SQL Server: $e');
    }
    if (mounted) setState(() => dangLuu = false);
  }

  void dienForm(MonHoc mon) {
    setState(() {
      maMonController.text = mon.maMon;
      tenMonController.text = mon.tenMon;
      gioHoc = mon.gioHoc;
      coSo = dsCoSo.firstWhere(
        (e) => e.ten == mon.coSo,
        orElse: () => dsCoSo.first,
      );
    });
  }

  // danh sách môn đã lưu trong SQL Server
  void moDanhSach() async {
    List<MonHoc> ds;
    try {
      ds = await controller.layDanhSach();
    } catch (e) {
      thongBao('$e');
      return;
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (sheet) => ds.isEmpty
          ? const SizedBox(
              height: 120,
              child: Center(child: Text('Chưa có môn học nào')),
            )
          : ListView(
              shrinkWrap: true,
              children: [
                for (final mon in ds)
                  ListTile(
                    title: Text('${mon.maMon} - ${mon.tenMon}'),
                    subtitle: Text(
                      '${mon.coSo}${mon.gioHoc == null ? '' : ' - ${dinhDang(mon.gioHoc!)}'}',
                    ),
                    onTap: () {
                      Navigator.pop(sheet);
                      dienForm(mon);
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        Navigator.pop(sheet);
                        try {
                          await controller.xoa(mon);
                          if (mounted) thongBao('Đã xóa ${mon.maMon}');
                        } catch (e) {
                          if (mounted) thongBao('$e');
                        }
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  String dinhDang(DateTime t) => DateFormat('dd/MM/yyyy HH:mm').format(t);

  Widget oNhap(String nhan, IconData icon, TextEditingController c) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: nhan,
        prefixIcon: Icon(icon, size: 20),
        prefixIconConstraints: const BoxConstraints(minWidth: 38),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: oNhap('Mã môn', Icons.tag, maMonController),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 6,
                        child: oNhap(
                          'Tên môn',
                          Icons.menu_book,
                          tenMonController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: [
                        for (final c in dsCoSo)
                          ButtonSegment(
                            value: c.ten,
                            label: Text(c.ten),
                            icon: const Icon(Icons.location_city, size: 18),
                          ),
                      ],
                      selected: {coSo.ten},
                      onSelectionChanged: (chon) => setState(() {
                        coSo = dsCoSo.firstWhere((e) => e.ten == chon.first);
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: chonGioHoc,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F6FB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    gioHoc == null
                                        ? 'Chọn giờ học'
                                        : dinhDang(gioHoc!),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Môn đã lưu',
                        icon: const Icon(Icons.list_alt),
                        onPressed: moDanhSach,
                      ),
                      const SizedBox(width: 4),
                      FilledButton.icon(
                        onPressed: dangLuu ? null : luu,
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('Lưu'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: BanDoView(coSo: coSo)),
        ],
      ),
    );
  }
}
