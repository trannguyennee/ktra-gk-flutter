import 'package:flutter/foundation.dart';
import '../models/mon_hoc.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class MonHocController {
  final ApiService _api = ApiService();
  final NotificationService _thongBao = NotificationService();

  Future<List<MonHoc>> layDanhSach() => _api.layDanhSachMonHoc();

  Future<bool> _datNhac(MonHoc mon, {required bool hoiQuyen}) {
    return _thongBao.datLichGioHoc(
      id: mon.idThongBao,
      tieuDe: 'Đến giờ học: ${mon.tenMon}',
      noiDung: 'Mã môn ${mon.maMon} - Cơ sở ${mon.coSo}',
      thoiGian: mon.gioHoc!,
      hoiQuyen: hoiQuyen,
    );
  }

  // Câu 3 + 5: lưu vào SQL Server và đặt thông báo trên máy này
  Future<String> luu(MonHoc mon) async {
    var thongBao = 'Chưa chọn giờ học nên không đặt thông báo';
    if (mon.gioHoc != null) {
      if (mon.gioHoc!.isAfter(DateTime.now())) {
        final chinhXac = await _datNhac(mon, hoiQuyen: true);
        thongBao = chinhXac
            ? 'Đã đặt thông báo đúng giờ học'
            : 'Đã đặt thông báo, có thể lệch vài phút vì chưa cấp quyền báo thức';
      } else {
        await _thongBao.huyLich(mon.idThongBao);
        thongBao = 'Giờ học đã qua nên không đặt thông báo';
      }
    }

    await _api.luuMonHoc(mon);
    return 'Đã lưu vào SQL Server. $thongBao';
  }

  Future<void> xoa(MonHoc mon) async {
    await _thongBao.huyLich(mon.idThongBao);
    await _api.xoaMonHoc(mon.maMon);
  }

  // Máy còn lại trong nhóm cũng nhận được thông báo của các môn đã lưu trên server
  Future<void> dongBoNhacGio() async {
    try {
      final ds = await _api.layDanhSachMonHoc();
      for (final mon in ds) {
        if (mon.gioHoc != null && mon.gioHoc!.isAfter(DateTime.now())) {
          await _datNhac(mon, hoiQuyen: false);
        }
      }
    } catch (e) {
      debugPrint('Chưa đồng bộ được giờ học: $e');
    }
  }
}
