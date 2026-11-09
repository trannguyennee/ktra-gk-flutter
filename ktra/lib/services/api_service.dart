import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mon_hoc.dart';
import '../models/sinh_vien.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const String _khoaUrl = 'api_url';
  static const String urlMacDinh = 'http://192.168.40.197:5000';
  static String baseUrl = urlMacDinh;

  // Địa chỉ API đổi theo mạng Wi-Fi nên cho nhập trong app
  static Future<void> taiCauHinh() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString(_khoaUrl) ?? urlMacDinh;
  }

  static Future<void> luuCauHinh(String url) async {
    var u = url.trim();
    if (!u.startsWith('http')) u = 'http://$u';
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    baseUrl = u;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_khoaUrl, u);
  }

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=utf-8',
  };
  static const Duration _thoiGianCho = Duration(seconds: 8);

  // Gọi API và đổi lỗi mạng thành câu dễ hiểu
  Future<http.Response> _goi(Future<http.Response> Function() yeuCau) async {
    try {
      final res = await yeuCau().timeout(_thoiGianCho);
      if (res.statusCode >= 400 && res.statusCode != 404) {
        throw ApiException('Máy chủ báo lỗi (${res.statusCode})');
      }
      return res;
    } on SocketException {
      throw ApiException('Không kết nối được API, kiểm tra địa chỉ và Wi-Fi');
    } on TimeoutException {
      throw ApiException('API không phản hồi, kiểm tra địa chỉ và Wi-Fi');
    } on http.ClientException {
      throw ApiException('Không kết nối được API, kiểm tra địa chỉ và Wi-Fi');
    }
  }

  Uri _uri(String duongDan) => Uri.parse('$baseUrl$duongDan');

  Future<bool> kiemTraKetNoi() async {
    try {
      final res = await http
          .get(_uri('/api/ping'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ================ SINH VIÊN ================
  Future<List<SinhVien>> layDanhSachSinhVien() async {
    final res = await _goi(() => http.get(_uri('/api/sinhvien')));
    final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => SinhVien.fromJson(e)).toList();
  }

  // Trả về số sinh viên thêm mới và số bị trùng
  Future<({int them, int trung})> nhapSinhVien(List<SinhVien> ds) async {
    final res = await _goi(
      () => http.post(
        _uri('/api/sinhvien/nhap'),
        headers: _headers,
        body: jsonEncode(ds.map((e) => e.toJson()).toList()),
      ),
    );
    final data = jsonDecode(res.body);
    return (them: data['them'] as int, trung: data['trung'] as int);
  }

  Future<void> xoaSinhVien(String mssv) async {
    await _goi(
      () => http.delete(_uri('/api/sinhvien/${Uri.encodeComponent(mssv)}')),
    );
  }

  String urlAnh(String mssv) =>
      '$baseUrl/api/sinhvien/${Uri.encodeComponent(mssv)}/anh';

  Future<void> capNhatAnh(String mssv, Uint8List anh) async {
    final res = await _goi(
      () => http.put(
        Uri.parse(urlAnh(mssv)),
        headers: _headers,
        body: jsonEncode({'anhBase64': base64Encode(anh)}),
      ),
    );
    if (res.statusCode == 404) {
      throw ApiException('Sinh viên $mssv chưa có trong SQL Server');
    }
  }

  Future<Uint8List?> taiAnh(String mssv) async {
    final res = await _goi(() => http.get(Uri.parse(urlAnh(mssv))));
    return res.statusCode == 200 ? res.bodyBytes : null;
  }

  // ================ MÔN HỌC ================
  Future<List<MonHoc>> layDanhSachMonHoc() async {
    final res = await _goi(() => http.get(_uri('/api/monhoc')));
    final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => MonHoc.fromJson(e)).toList();
  }

  Future<void> luuMonHoc(MonHoc mon) async {
    await _goi(
      () => http.post(
        _uri('/api/monhoc'),
        headers: _headers,
        body: jsonEncode(mon.toJson()),
      ),
    );
  }

  Future<void> xoaMonHoc(String maMon) async {
    await _goi(
      () => http.delete(_uri('/api/monhoc/${Uri.encodeComponent(maMon)}')),
    );
  }
}
