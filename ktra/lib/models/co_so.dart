import 'package:latlong2/latlong.dart';

class CoSo {
  final String ten;
  final String diaChi;
  final LatLng toaDo;

  const CoSo(this.ten, this.diaChi, this.toaDo);
}

const List<CoSo> dsCoSo = [
  CoSo(
    'Nhà Bè',
    'Hẻm 1734/30 Lê Văn Lương, Xã Hiệp Phước, TP.HCM',
    LatLng(10.6778097, 106.6931033),
  ),
  CoSo(
    'Lê Văn Sỹ',
    '236B Lê Văn Sỹ, Tân Bình, TP.HCM',
    LatLng(10.7966448, 106.6667757),
  ),
];
