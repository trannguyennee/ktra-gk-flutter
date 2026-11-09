import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// Câu 4: định vị và tìm đường để vẽ polyline
class BanDoController {
  Future<void> moCaiDatGps() => Geolocator.openLocationSettings();

  // true khi người dùng vừa bật GPS, false khi vừa tắt
  Stream<bool> get gpsThayDoi => Geolocator.getServiceStatusStream().map(
    (trangThai) => trangThai == ServiceStatus.enabled,
  );

  // Trả về null kèm lý do khi không định vị được
  Future<({LatLng? viTri, String? loi})> layViTriHienTai() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return (viTri: null, loi: 'Hãy bật GPS (vị trí) trên điện thoại');
    }

    var quyen = await Geolocator.checkPermission();
    if (quyen == LocationPermission.denied) {
      quyen = await Geolocator.requestPermission();
    }
    if (quyen == LocationPermission.denied ||
        quyen == LocationPermission.deniedForever) {
      return (viTri: null, loi: 'Ứng dụng chưa được cấp quyền vị trí');
    }

    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (viTri: LatLng(p.latitude, p.longitude), loi: null);
    } catch (_) {
      final p = await Geolocator.getLastKnownPosition();
      if (p != null) {
        return (viTri: LatLng(p.latitude, p.longitude), loi: null);
      }
      return (viTri: null, loi: 'Chưa lấy được vị trí, thử lại ngoài trời');
    }
  }

  // Lấy đường đi từ OSRM, trả về danh sách điểm, độ dài (km) và thời gian (phút)
  Future<({List<LatLng> diem, double km, int phut})?> timDuong(
    LatLng tu,
    LatLng den,
  ) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${tu.longitude},${tu.latitude};${den.longitude},${den.latitude}'
        '?overview=full&geometries=polyline';
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      if (data['code'] != 'Ok' || (data['routes'] as List).isEmpty) return null;

      final route = data['routes'][0];
      return (
        diem: giaiMaPolyline(route['geometry']),
        km: (route['distance'] as num) / 1000,
        phut: ((route['duration'] as num) / 60).round(),
      );
    } catch (_) {
      return null;
    }
  }

  // Giải mã polyline giống bài tập chương 4
  static List<LatLng> giaiMaPolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0, lat = 0, lng = 0;

    int docSo() {
      var shift = 0, result = 0, b = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    }

    while (index < encoded.length) {
      lat += docSo();
      lng += docSo();
      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
