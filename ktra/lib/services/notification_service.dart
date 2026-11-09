import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Câu 5: thông báo đến giờ học
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
    );
    await _android?.requestNotificationsPermission();
  }

  // Trả về true nếu lịch đặt đúng giờ chính xác
  Future<bool> datLichGioHoc({
    required int id,
    required String tieuDe,
    required String noiDung,
    required DateTime thoiGian,
    bool hoiQuyen = false,
  }) async {
    var chinhXac = await _android?.canScheduleExactNotifications() ?? false;
    if (!chinhXac && hoiQuyen) {
      await _android?.requestExactAlarmsPermission();
      chinhXac = await _android?.canScheduleExactNotifications() ?? false;
    }

    const details = AndroidNotificationDetails(
      'gio_hoc_channel',
      'Nhắc giờ học',
      channelDescription: 'Thông báo khi đến giờ học',
      importance: Importance.max,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
    );

    await _plugin.zonedSchedule(
      id: id,
      title: tieuDe,
      body: noiDung,
      scheduledDate: tz.TZDateTime.from(thoiGian, tz.local),
      notificationDetails: const NotificationDetails(android: details),
      // chưa có quyền báo thức chính xác thì vẫn đặt lịch, có thể lệch vài phút
      androidScheduleMode: chinhXac
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return chinhXac;
  }

  Future<void> huyLich(int id) async {
    await _plugin.cancel(id: id);
  }
}
