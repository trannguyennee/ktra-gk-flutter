import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/ban_do_controller.dart';
import '../models/co_so.dart';

// Câu 4: chọn cơ sở thì bản đồ tới cơ sở đó, định vị và vẽ đường đi bằng OSRM
class BanDoView extends StatefulWidget {
  final CoSo coSo;

  const BanDoView({super.key, required this.coSo});

  @override
  State<BanDoView> createState() => _BanDoViewState();
}

class _BanDoViewState extends State<BanDoView> {
  final BanDoController controller = BanDoController();
  final MapController mapController = MapController();

  LatLng? viTri;
  List<LatLng> duongDi = [];
  String? thongTinDuong;
  String? loi;
  bool dangTai = false;
  bool banDoSanSang = false;
  bool canBatGps = false;
  StreamSubscription<bool>? theoDoiGps;

  @override
  void initState() {
    super.initState();
    dinhVi();
    // bật GPS trong lúc đang mở app thì tự định vị lại
    theoDoiGps = controller.gpsThayDoi.listen((batGps) {
      if (batGps && viTri == null && !dangTai) dinhVi();
    });
  }

  @override
  void dispose() {
    theoDoiGps?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BanDoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coSo.ten != widget.coSo.ten) {
      denCoSo();
      timDuong();
    }
  }

  void denCoSo() {
    if (banDoSanSang) mapController.move(widget.coSo.toaDo, 16);
  }

  void dinhVi() async {
    setState(() {
      dangTai = true;
      loi = null;
    });

    final kq = await controller.layViTriHienTai();
    if (!mounted) return;
    if (kq.viTri == null) {
      setState(() {
        dangTai = false;
        loi = kq.loi;
        canBatGps = kq.loi!.contains('GPS');
      });
      return;
    }

    canBatGps = false;
    viTri = kq.viTri;
    timDuong();
  }

  void timDuong() async {
    final tu = viTri;
    final coSo = widget.coSo;
    if (tu == null) return;

    setState(() {
      dangTai = true;
      duongDi = [];
      thongTinDuong = null;
    });

    final kq = await controller.timDuong(tu, coSo.toaDo);
    if (!mounted || coSo.ten != widget.coSo.ten) return;

    setState(() {
      dangTai = false;
      if (kq != null) {
        duongDi = kq.diem;
        thongTinDuong = '${kq.km.toStringAsFixed(1)} km · ${kq.phut} phút';
        loi = null;
      } else {
        loi = 'Chưa lấy được đường đi từ OSRM, kiểm tra mạng';
      }
    });
  }

  void xemToanTuyen() {
    final diem = [widget.coSo.toaDo, ?viTri, ...duongDi];
    if (!banDoSanSang || diem.length < 2) return;
    mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(diem),
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 110),
      ),
    );
  }

  void veViTriCuaToi() {
    if (viTri != null && banDoSanSang) mapController.move(viTri!, 16);
    dinhVi();
  }

  Widget nutTron(IconData icon, String goiY, VoidCallback? onPressed) {
    return IconButton.filledTonal(
      tooltip: goiY,
      onPressed: onPressed,
      style: IconButton.styleFrom(backgroundColor: Colors.white),
      icon: Icon(icon, color: const Color(0xFF1565C0)),
    );
  }

  Widget theThongTin() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Row(
        children: [
          const Icon(Icons.school, color: Color(0xFFD32F2F)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cơ sở ${widget.coSo.ten}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  widget.coSo.diaChi,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                if (loi != null)
                  Text(
                    loi!,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  )
                else if (dangTai)
                  const Text(
                    'Đang định vị và tìm đường...',
                    style: TextStyle(fontSize: 12),
                  )
                else if (thongTinDuong != null)
                  Text(
                    'Từ vị trí của bạn: $thongTinDuong',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          if (canBatGps)
            TextButton(
              onPressed: controller.moCaiDatGps,
              child: const Text('Bật GPS'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: widget.coSo.toaDo,
              initialZoom: 16,
              backgroundColor: const Color(0xFFE8EEF5),
              // tắt xoay bản đồ để ghim và chữ luôn thẳng
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () => banDoSanSang = true,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ktra',
              ),
              PolylineLayer(
                polylines: [
                  if (duongDi.isNotEmpty)
                    Polyline(
                      points: duongDi,
                      strokeWidth: 6,
                      color: const Color(0xFF1E88E5),
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.coSo.toaDo,
                    width: 48,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFFD32F2F),
                      size: 48,
                    ),
                  ),
                  if (viTri != null)
                    Marker(
                      point: viTri!,
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Column(
              children: [
                nutTron(Icons.school, 'Về cơ sở', denCoSo),
                nutTron(
                  Icons.alt_route,
                  'Xem toàn tuyến',
                  duongDi.isEmpty ? null : xemToanTuyen,
                ),
                nutTron(
                  Icons.my_location,
                  'Vị trí của tôi',
                  dangTai ? null : veViTriCuaToi,
                ),
              ],
            ),
          ),
          Positioned(left: 10, right: 10, bottom: 10, child: theThongTin()),
          Positioned(
            left: 12,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: Colors.white70,
              child: const Text(
                '© OpenStreetMap',
                style: TextStyle(fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
