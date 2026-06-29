import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config.dart';
import '../services/jadwal_service.dart';
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

      if (userId == 0) {
        setState(() => isLoading = false);
        return;
      }

      final result = await JadwalService.getJadwalKurir(userId);

      if (!mounted) return;
      setState(() {
        jadwalList = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR FETCH JADWAL: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> mulaiJemputKurir(int jadwalId) async {
    try {
      setState(() => isLoading = true);

      final result = await JadwalService.mulaiJemput(jadwalId);

      if (result['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("STATUS TUGAS: DALAM PROSES PENJEMPUTAN!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.blueAccent,
            duration: Duration(seconds: 3),
          ),
        );
        await getJadwal();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "GAGAL MENGUBAH STATUS!"),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("ERROR CRITICAL SAAT KLIK TOMBOL JEMPUT: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Terjadi kesalahan koneksi: $e"), backgroundColor: Colors.redAccent)
        );
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredList = jadwalList.where((item) {
      String status = (item['status'] ?? 'terjadwal').toString().toLowerCase();
      bool matchFilter = true;

      if (selectedFilter == "Hari Ini") {
        matchFilter = (status != 'selesai' && status != 'completed' && status != 'dibatalkan');
      } else if (selectedFilter == "Proses") {
        matchFilter = (status == 'proses' || status == 'dalam_perjalanan' || status == 'on_progress');
      } else if (selectedFilter == "Selesai") {
        matchFilter = (status == 'selesai' || status == 'completed');
      }

      String nama = _resolveNamaNasabah(item).toLowerCase();
      bool matchSearch = nama.contains(searchQuery.toLowerCase());

      return matchFilter && matchSearch;
    }).toList();

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
                ? SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    jadwalList.isEmpty
                        ? "Tidak ada data dari server.\n\nSilakan tarik ke bawah layar untuk memuat ulang."
                        : "Data ada tapi tidak cocok dengan filter '$selectedFilter'.\n\nCoba pilih tombol filter 'Semua'.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: greyTextColor, fontSize: 18, fontWeight: FontWeight.bold),
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

                    String kategori = "Jadwal Khusus";
                    Color kategoriColor = Colors.purple.shade800;
                    final String tipe = (item['tipe'] ?? item['kategori'] ?? '').toString().toLowerCase();
                    if (tipe == 'rutin' || item['is_rutin'] == true || item['rutin_id'] != null) {
                      kategori = "Jadwal Rutin"; kategoriColor = primaryColor;
                    } else if (tipe == 'request' || item['request_id'] != null) {
                      kategori = "Request Nasabah"; kategoriColor = Colors.blue.shade800;
                    }

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
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
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
              Text("ID: #$id", style: const TextStyle(fontSize: 14, color: greyTextColor, fontWeight: FontWeight.bold)),
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