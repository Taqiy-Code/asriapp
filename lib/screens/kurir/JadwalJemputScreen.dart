import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config.dart';
import 'ScanBarcode.dart';
import 'navigasi_kurir_page.dart';

const primaryColor = Color(0xFF1E521E);
const backgroundColor = Color(0xFFF9FBF9);
const darkTextColor = Color(0xFF0D240D);
const greyTextColor = Color(0xFF444444);
const softGreenColor = Color(0xFFE8F5E9);

class JadwalJemputScreen extends StatefulWidget {
  const JadwalJemputScreen({super.key});

  @override
  State<JadwalJemputScreen> createState() => _JadwalJemputScreenState();
}

class _JadwalJemputScreenState extends State<JadwalJemputScreen> {
  List<dynamic> jadwalList = [];
  bool isLoading = true;
  String selectedFilter = "Semua";
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    getJadwal();
  }

  // 🔥 FUNGSI INTEROGASI UTAMA: Mengambil data langsung tanpa perantara service kaku
  Future<void> getJadwal() async {
    try {
      setState(() => isLoading = true);
      SharedPreferences prefs = await SharedPreferences.getInstance();

      int userId = 0;
      var rawId = prefs.get('user_id');
      if (rawId is int) {
        userId = rawId;
      } else if (rawId is String) {
        userId = int.tryParse(rawId) ?? 0;
      }

      // CEK 1: Apakah ID Kurir tersimpan di HP?
      if (userId == 0) {
        setState(() => isLoading = false);
        _bukaDialogInterogasi("⚠️ MASALAH LOGIN:\nID Kurir di HP terbaca 0. Silakan LOGOUT lalu LOGIN ulang ke akun Yono Bakrie agar ID tersimpan di memori HP!");
        return;
      }

      final token = prefs.getString('token') ?? '';
      final url = Uri.parse('${AppConfig.baseUrl}/kurir/jadwal/$userId');

      // Bypass SSL untuk cPanel Hosting
      final ioClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      final secureClient = IOClient(ioClient);

      final response = await secureClient.get(
        url,
        headers: {
          "Accept": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (!mounted) return;
      setState(() {
        jadwalList = body['data'] ?? [];
        isLoading = false;
      });

      // CEK 2: Berhasil tebak respons server cPanel
      if (jadwalList.isEmpty) {
        // _bukaDialogInterogasi("ℹ️ RESPONS SERVER KOSONG:\nKoneksi ke cPanel SUKSES, ID Kurir yang menembak adalah ($userId). Tapi server mengirim balik 0 data. Silakan cek tabel 'jadwal_penjemputans' di phpMyAdmin, pastikan ada baris data dengan kurir_id = $userId dan statusnya berbunyi 'terjadwal' atau 'proses'!");
      } else {
        // _bukaDialogInterogasi("🎉 BERHASIL DAN TEMBUS!\nServer mengirimkan ${jadwalList.length} data tugas untuk ID Kurir $userId. Data otomatis tampil di bawah!");
      }

    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      // _bukaDialogInterogasi("💥 CRASH SISTEM FLUTTER:\nGagal terhubung atau format JSON salah. Detail Error: $e");
    }
  }

  // Fungsi Pop-up Sakti Penebak Masalah
  void _bukaDialogInterogasi(String pesan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("🔍 Hasil Interogasi Sistem", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
        content: Text(pesan, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text("SAYA PAHAM", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> mulaiJemputKurir(int jadwalId) async {
    try {
      setState(() => isLoading = true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final ioClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      final secureClient = IOClient(ioClient);

      // 🚨 CETAK UNTUK DEBUGGING
      print("Mengirim request ke: ${AppConfig.baseUrl}/kurir/mulai-jemput/$jadwalId");

      final response = await secureClient.post(
        Uri.parse('${AppConfig.baseUrl}/kurir/mulai-jemput/$jadwalId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': 'proses'}),
      );

      // 🚨 CETAK RESPONS ASLI SERVER
      print("Status Code Server: ${response.statusCode}");
      print("Isi Respons Server: ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("⚠️ STATUS TUGAS: DALAM PROSES PENJEMPUTAN!"),
              backgroundColor: Colors.blueAccent
          ),
        );
        await getJadwal(); // Refresh data setelah berhasil
      } else {
        // Mengurai pesan error dari server jika ada
        String pesanGagal = "Gagal mengubah status! (Code: ${response.statusCode})";
        try {
          var errorBody = jsonDecode(response.body);
          if (errorBody['message'] != null) {
            pesanGagal = "Server berkata: ${errorBody['message']}";
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pesanGagal),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Crash di Flutter: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Crash Flutter: $e"), backgroundColor: Colors.redAccent),
        );
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 BYPASS FILTER FLUTTER: Data langsung dialirkan murni tanpa disaring agar tidak hilang di layar
    List<dynamic> filteredList = List.from(jadwalList);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 5))
          : RefreshIndicator(
        color: primaryColor,
        onRefresh: getJadwal,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, bottom: 24, left: 16, right: 16),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 26), onPressed: () => Navigator.pop(context)),
                        const Text("Daftar Tugas", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                        IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 28), onPressed: getJadwal),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                        "Terdeteksi ${jadwalList.length} total tugas di sistem",
                        style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: SizedBox(
                  height: 46,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: ["Semua", "Hari Ini", "Proses", "Selesai"].map((f) => _buildFilterChip(f)).toList(),
                  ),
                ),
              ),
            ),

            filteredList.isEmpty
                ? const SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    "Tidak ada data tugas aktif untuk Kurir hari ini.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: greyTextColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
                : SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final item = filteredList[index];

                    String kategori = "Jadwal Rutin";
                    Color kategoriColor = primaryColor;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: JadwalCard(
                        id: int.tryParse(item['id'].toString()) ?? 0,
                        nama: _resolveNamaNasabah(item),
                        alamat: item['alamat'] ?? 'Alamat tidak tersedia',
                        status: (item['status'] ?? 'terjadwal').toString(),
                        kategori: kategori,
                        kategoriColor: kategoriColor,
                        onLihatLokasi: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NavigasiKurirPage(initialJadwalData: item))),
                        onMulaiJemput: () async {
                          String st = (item['status'] ?? '').toString().toLowerCase();
                          if (st == 'terjadwal' || st == 'pending') {
                            await mulaiJemputKurir(int.parse(item['id'].toString()));
                          } else {
                            int idNasabah = int.tryParse(item['nasabah_id']?.toString() ?? '') ?? int.tryParse(item['user_id']?.toString() ?? '') ?? 0;
                            final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => ScanBarcodePage(jadwalId: int.parse(item['id'].toString()), nasabahId: idNasabah)));
                            if (res == true) getJadwal();
                          }
                        },
                      ),
                    );
                  },
                  childCount: filteredList.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = selectedFilter == label;
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryColor, width: 2)
      ),
      alignment: Alignment.center,
      child: Text(
          label,
          style: TextStyle(
              color: isSelected ? Colors.white : primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 16
          )
      ),
    );
  }

  String _resolveNamaNasabah(dynamic j) {
    if (j == null) return 'Nasabah';
    var n = j['nasabah'] ?? j['user'];
    if (n != null && n is Map) {
      var name = n['name'] ?? n['nama'] ?? (n['user'] != null ? n['user']['name'] ?? n['user']['nama'] : null);
      if (name != null) return name.toString();
    }
    var direct = j['nasabah_name'] ?? j['user_name'] ?? j['nama_nasabah'] ?? j['nama'] ?? j['name'];
    if (direct != null) return direct.toString();
    return 'Nasabah ASRI';
  }
}

class JadwalCard extends StatelessWidget {
  final int id;
  final String nama;
  final String alamat;
  final String status;
  final String kategori;
  final Color kategoriColor;
  final VoidCallback onLihatLokasi;
  final VoidCallback onMulaiJemput;

  const JadwalCard({super.key, required this.id, required this.nama, required this.alamat, required this.status, required this.kategori, required this.kategoriColor, required this.onLihatLokasi, required this.onMulaiJemput});

  @override
  Widget build(BuildContext context) {
    String st = status.toLowerCase();
    Color statusColor = (st == 'selesai' || st == 'completed')
        ? Colors.green.shade900
        : (st == 'terjadwal' || st == 'pending' ? Colors.orange.shade900 : Colors.blue.shade900);

    bool isProses = (st == 'proses' || st == 'dalam_perjalanan' || st == 'on_progress');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: kategoriColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(kategori.toUpperCase(), style: TextStyle(color: kategoriColor, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
              // Baris ID: #$id sebelumnya ada di sini dan sudah dihapus agar tampilan lebih bersih
            ],
          ),
          const SizedBox(height: 14),
          Text(nama, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: darkTextColor, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Icon(Icons.location_on_rounded, size: 20, color: primaryColor),
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(alamat, style: const TextStyle(fontSize: 16, color: darkTextColor, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.grey.shade300, thickness: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Status Tugas:", style: TextStyle(fontSize: 15, color: greyTextColor, fontWeight: FontWeight.bold)),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w900))
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLihatLokasi,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    side: const BorderSide(color: primaryColor, width: 2.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.map_rounded, color: primaryColor, size: 22),
                  label: const Text("LIHAT RUTE", style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onMulaiJemput,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isProses ? Colors.orange.shade800 : primaryColor,
                    minimumSize: const Size(0, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  icon: Icon(isProses ? Icons.scale_rounded : Icons.local_shipping_rounded, color: Colors.white, size: 22),
                  label: Text(
                      st == 'terjadwal' || st == 'pending' ? "MULAI JEMPUT" : "TIMBANG",
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}