import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/dashboard_kurir_service.dart';
import '../../config.dart'; // 🔥 FILE UTAMA YANG KITA GUNAKAN
import '../kurir/SetorSampahPage.dart';
import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong2.dart';

// 🎨 PALET WARNA KONSISTEN SENIOR-FRIENDLY ASRI / BASAYAN BESTARI
const primaryColor = Color(0xFF1E521E);
const secondaryColor = Color(0xFF4CAF50);
const softGreenColor = Color(0xFFE8F5E9);
const backgroundColor = Color(0xFFF9FBF9);
const darkTextColor = Color(0xFF0D240D);
const greyTextColor = Color(0xFF555555);

class NavigasiKurirPage extends StatefulWidget {
  const NavigasiKurirPage({super.key});

  @override
  State<NavigasiKurirPage> createState() => _NavigasiKurirPageState();
}

class _NavigasiKurirPageState extends State<NavigasiKurirPage> {
  int _pageIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _liveJadwalData;

  // 📝 VARIABEL INTEGRASI DATABASE SIMPASDA
  int nasabahId = 0;
  String namaNasabah = "Memuat...";
  String alamatNasabah = "Memuat...";
  String catatanNasabah = "Tidak ada catatan";
  int jadwalId = 0;

  // 📍 KOORDINAT DEFAULT (Akan ditimpa jika ada data koordinat asli dari MySQL)
  LatLng koordinatPusat = const LatLng(-6.2088, 106.8456);

  @override
  void initState() {
    super.initState();
    _loadDataJadwalDariDatabase();
  }

  Future<void> _loadDataJadwalDariDatabase() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int userId = prefs.getInt('user_id') ?? 0; // ID Kurir yang login

      if (userId == 0) {
        setState(() { _isLoading = false; });
        return;
      }

      print("DEBUG MAI - Membuka Navigasi Rute via Base URL: ${AppConfig.baseUrl}");

      final result = await DashboardKurirService.getDashboard(userId);

      if (result != null && result['jadwal'] != null) {
        final jadwalObj = result['jadwal'];
        final nasabahObj = jadwalObj['user'] ?? jadwalObj['nasabah'];
        setState(() {
          _liveJadwalData = result;

          jadwalId = int.tryParse(jadwalObj['id'].toString()) ?? 0;
          nasabahId = int.tryParse(jadwalObj['nasabah_id'].toString()) ?? int.tryParse(jadwalObj['user_id'].toString()) ?? 0;
          namaNasabah = nasabahObj?['nama'] ?? "Nasabah Basayan Bestari";
          alamatNasabah = jadwalObj['alamat'] ?? "Alamat tidak diisi";
          catatanNasabah = jadwalObj['catatan'] ?? "Ambil sampah penjemputan";

          // 🔥 SINKRONISASI GEOLOKASI: Baca koordinat rumah nasabah dari database jika tersedia
          if (jadwalObj['latitude'] != null && jadwalObj['longitude'] != null) {
            koordinatPusat = LatLng(
              double.parse(jadwalObj['latitude'].toString()),
              double.parse(jadwalObj['longitude'].toString()),
            );
          }

          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      print("DEBUG MAI - Gagal sinkronisasi peta rute: $e");
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 4)),
      );
    }

    if (jadwalId == 0) {
      return Scaffold(
        appBar: AppBar(backgroundColor: primaryColor, title: const Text("Peta Rute")),
        body: const Center(
          child: Text("☕ Tidak ada rute jalan aktif untuk hari ini.", style: TextStyle(fontWeight: FontWeight.bold, color: greyTextColor)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: IndexedStack(
        index: _pageIndex,
        children: [
          _buildHalamanPetaRute(),
          _buildHalamanNavigasiDetail(),
        ],
      ),
    );
  }

  // =========================================================================
  // 🗺️ HALAMAN 1: PETA RUTE JALAN (MULTI-STOP OVERLAY MAP)
  // =========================================================================
  Widget _buildHalamanPetaRute() {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Peta Rute", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
      ),
      body: Stack(
        children: [

          // 🔥 SEKARANG INSTAN TAMPIL: Peta Interaktif Digital Terintegrasi
          FlutterMap(
            options: MapOptions(
              initialCenter: koordinatPusat,
              initialZoom: 15.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.asriapp.app',
              ),
              MarkerLayer(
                markers: [
                  // Pin Lokasi Master Bank Sampah Basayan Bestari
                  Marker(
                    point: const LatLng(-6.2088, 106.8456),
                    width: 45,
                    height: 45,
                    child: const Icon(Icons.home_work_rounded, color: primaryColor, size: 42),
                  ),
                  // Pin Dinamis Rumah Warga (Mengikuti koordinat database)
                  Marker(
                    point: koordinatPusat,
                    width: 45,
                    height: 45,
                    child: const Icon(Icons.location_on_rounded, color: Colors.orange, size: 45),
                  ),
                ],
              ),
            ],
          ),

          // Label Mengambang Atas Penanda Koneksi Server Aktif Skripsi
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Text(
                "📡 Server: ${AppConfig.baseUrl.replaceAll('/api', '')} | Rute: $alamatNasabah",
                textAlign: TextAlign.center,
                style: const TextStyle(color: darkTextColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Draggable Bottom Sheet Informasi Rute Anda
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.35,
            maxChildSize: 0.80,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.only(top: 12, left: 20, right: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
                ),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(child: Container(width: 46, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),
                    const Text("Rute Perjalanan Hari Ini", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: darkTextColor)),
                    const SizedBox(height: 20),

                    _buildRouteNode("🏠", "Bank Sampah Basayan Bestari", "Lokasi Awal", isFirst: true),
                    _buildRouteNode("1", namaNasabah, "$alamatNasabah • [$catatanNasabah]", dist: "Aktif"),
                    _buildRouteNode("2", "Tujuan Selanjutnya", "Menunggu giliran tugas berikutnya", dist: "--", isLast: true),

                    const Divider(height: 32, thickness: 1.2),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFooterStats("Total Tugas", "${_liveJadwalData?['total_pesanan'] ?? 1} Lokasi"),
                        _buildFooterStats("Selesai", "${_liveJadwalData?['total_pesanan_selesai'] ?? 0} Lokasi"),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        onPressed: () => setState(() => _pageIndex = 1),
                        icon: const Icon(Icons.navigation_rounded, color: Colors.white),
                        label: const Text("Mulai Panduan Arah", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 🧭 HALAMAN 2: PETUNJUK NAVIGASI REAL-TIME (TURN-BY-TURN MAP)
  // =========================================================================
  Widget _buildHalamanNavigasiDetail() {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => setState(() => _pageIndex = 0),
        ),
        title: const Text("Panduan Navigasi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Banner Atas: Panduan Belokan Turn-by-Turn Super Kontras
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: darkTextColor,
            child: Row(
              children: [
                const Icon(Icons.directions_bike_rounded, color: Colors.white, size: 52),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Panduan Jalan", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 2),
                      Text("Menuju alamat nasabah di $alamatNasabah", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              ],
            ),
          ),

          // 🔥 MAP KEDUA: Peta Navigasi Mengikuti Pergerakan Real-time Kurir
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: koordinatPusat,
                initialZoom: 16.5, // Zoom lebih dekat agar mempermudah kurir melihat jalan lansia
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.asriapp.app',
                ),
                MarkerLayer(
                  markers: [
                    // Penanda Posisi Kurir Bergerak Aktif
                    Marker(
                      point: koordinatPusat,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.navigation_rounded, color: Colors.blue, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Sheet Panel Informasi Target & Konfirmasi Tiba
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -2))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.orange.shade100,
                      child: const Icon(Icons.person_pin_circle_rounded, color: Colors.orange, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("TUGAS AKTIF JADWAL ID: #$jadwalId", style: const TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(namaNasabah, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: darkTextColor)),
                          Text("📍 $alamatNasabah", style: const TextStyle(color: greyTextColor, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Catatan Warga", style: TextStyle(fontWeight: FontWeight.bold)),
                              content: Text('"$catatanNasabah"'),
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Ok"))],
                            ),
                          );
                        },
                        child: const Text("Lihat Catatan", style: TextStyle(fontWeight: FontWeight.w900, color: darkTextColor, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          final hasilSetor = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SetorSampahPage(
                                nasabahId: nasabahId,
                                namaNasabah: namaNasabah,
                                alamat: alamatNasabah,
                                barcode: "BRC-${nasabahId}99",
                                jadwalId: jadwalId,
                              ),
                            ),
                          );
                          if (hasilSetor == true) {
                            if (mounted) Navigator.pop(context, true);
                          }
                        },
                        child: const Text("Saya Sampai", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRouteNode(String badge, String title, String subtitle, {String dist = "", bool isFirst = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isFirst ? softGreenColor : Colors.orange.shade50,
              child: Text(badge, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isFirst ? primaryColor : Colors.orange.shade900)),
            ),
            if (!isLast) Container(width: 2.5, height: 42, color: Colors.grey.shade200),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: darkTextColor)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: greyTextColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (dist.isNotEmpty) Text(dist, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: primaryColor)),
      ],
    );
  }

  Widget _buildFooterStats(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: greyTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: darkTextColor)),
      ],
    );
  }
}