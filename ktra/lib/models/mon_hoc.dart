class MonHoc {
  String maMon;
  String tenMon;
  String coSo;
  DateTime? gioHoc;

  MonHoc({
    required this.maMon,
    required this.tenMon,
    required this.coSo,
    this.gioHoc,
  });

  factory MonHoc.fromJson(Map<String, dynamic> json) {
    return MonHoc(
      maMon: json['maMon'],
      tenMon: json['tenMon'],
      coSo: json['coSo'],
      gioHoc: json['gioHoc'] == null ? null : DateTime.parse(json['gioHoc']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maMon': maMon,
      'tenMon': tenMon,
      'coSo': coSo,
      'gioHoc': gioHoc?.toIso8601String(),
    };
  }

  // id thông báo cố định theo mã môn, để lưu lại môn cũ thì thay lịch cũ
  int get idThongBao {
    var h = 7;
    for (final c in maMon.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }
}
