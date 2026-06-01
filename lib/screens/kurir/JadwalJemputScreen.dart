import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config.dart';
import '../services/jadwal_service.dart';
import 'ScanBarcode.dart';
import 'SetorSampahPage.dart';
import 'navigasi_kurir_page.dart'; // 🔥 Pastikan import halaman navigasi sudah aktif

// Palet warna kontras tinggi (Senior-Friendly Theme)
const primaryColor = Color(0xFF1E521E);     // Hijau tua pekat
const secondaryColor = Color(0xFF4CAF50);   // Hijau aksen cerah
const softGreenColor = Color(0xFFE8F5E9);   // Komponen background hijau lembut
const backgroundColor = Color(0xFFF9FBF9);  // Putih bersih maksimal
const darkTextColor = Color(0xFF0D240D);    // Teks super pekat (keterbacaan prima)
const greyTextColor = Color(0xFF555555);    // Abu-abu gelap kontras tinggi

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

  Future<void> mulaiJemputKurir(int jadwalId) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/jadwal-penjemputan/$jadwalId/mulai'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("STATUS TUGAS: DALAM PROSES PENJEMPUTAN!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            backgroundColor: Colors.blueAccent,
            duration: Duration(seconds: 3),
          ),
        );
        getJadwal();
      } else {
        print("Gagal memperbarui status penjemputan");
      }
    } catch (e) {
      print("Error koneksi penjemputan: $e");
    }
  }

  Future<void> getJadwal() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int userId = prefs.getInt('user_id') ?? 0;
      final result = await JadwalService.getJadwalKurir(userId);

      setState(() {
        jadwalList = result;
        isLoading = false;
      });
    } catch (e) {
      print("DEBUG MAI JADWAL ERROR: $e");
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 4)),
      );
    }

    List<dynamic> filteredList = jadwalList.where((jadwal) {
      String status = (jadwal['status'] ?? 'terjadwal').toString().toLowerCase();
      bool matchFilter = true;
      if (selectedFilter == "Hari Ini") matchFilter = (status == 'terjadwal' || status == 'proses');
      else if (selectedFilter == "Proses") matchFilter = (status == 'proses');
      else if (selectedFilter == "Selesai") matchFilter = (status == 'selesai' || status == 'completed');

      String namaNasabah = (jadwal['nasabah']?['name'] ?? '').toString().toLowerCase();
      String alamatTugas = (jadwal['alamat'] ?? '').toString().toLowerCase();
      bool matchSearch = namaNasabah.contains(searchQuery.toLowerCase()) || alamatTugas.contains(searchQuery.toLowerCase());

      return matchFilter && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // ================= HEADER FIXED =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, Color(0xFF2E6B2E)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 26),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          "Jadwal Penjemputan",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 28),
                        onPressed: () => getJadwal(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      "Ada ${filteredList.length} tugas penjemputan aktif",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ================= SEARCH BAR =================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() { searchQuery = value; });
              },
              style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "Cari nama nasabah atau alamat...",
                hintStyle: const TextStyle(color: greyTextColor),
                prefixIcon: const Icon(Icons.search_rounded, color: primaryColor),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: greyTextColor),
                  onPressed: () {
                    searchController.clear();
                    setState(() { searchQuery = ""; });
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
          ),

          // ================= FILTER CHIPS =================
          SizedBox(
            height: 45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip("Semua"),
                _buildFilterChip("Hari Ini"),
                _buildFilterChip("Proses"),
                _buildFilterChip("Selesai"),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ================= CARDS LIST =================
          Expanded(
            child: filteredList.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_late_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    "Tidak ada jadwal penjemputan",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              color: primaryColor,
              onRefresh: getJadwal,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final item = filteredList[index];

                  String jamFormatted = "--:--";
                  if (item['created_at'] != null && item['created_at'].toString().length >= 16) {
                    try {
                      jamFormatted = item['created_at'].toString().substring(11, 16);
                    } catch (e) {
                      jamFormatted = "--:--";
                    }
                  }

                  String displayStatus = (item['status'] ?? 'terjadwal').toString().toLowerCase();
                  bool isTerjadwal = (displayStatus == 'terjadwal' || displayStatus == 'pending');
                  bool isProses = (displayStatus == 'proses' || displayStatus == 'on_progress');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: JadwalCard(
                      id: item['id'] ?? 0,
                      nama: item['nasabah']?['name'] ?? 'Tanpa Nama',
                      alamat: item['alamat'] ?? 'Alamat tidak tersedia',
                      jam: jamFormatted,
                      status: displayStatus,
                      // 🔥 AKSI TOMBOL LIHAT LOKASI: Pindah ke halaman Navigasi rute map
                      onLihatLokasi: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NavigasiKurirPage(),
                          ),
                        );
                      },
                      onMulaiJemput: () async {
                        if (isTerjadwal) {
                          mulaiJemputKurir(item['id']);
                        } else if (isProses) {
                          final refresh = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScanBarcodePage(jadwalId: item['id']),
                            ),
                          );
                          if (refresh == true) {
                            getJadwal();
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // ================= FLOATING ACTION SCANNER =================
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 72,
        width: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: primaryColor,
          shape: const CircleBorder(),
          onPressed: () async {
            int idJadwalTerpilih = jadwalList.isNotEmpty ? jadwalList[0]['id'] : 0;
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ScanBarcodePage(jadwalId: idJadwalTerpilih)),
            );

            if (result == true) {
              getJadwal();
            }
          },
          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 32),
        ),
      ),

      // ================= BOTTOM NAV BAR =================
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        elevation: 24,
        color: Colors.white,
        shadowColor: primaryColor.withOpacity(0.4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              icon: Icons.home_rounded,
              label: "Beranda",
              active: true,
              onTap: () => Navigator.pop(context, true),
            ),
            _navItem(icon: Icons.assignment_turned_in_rounded, label: "Riwayat", onTap: () {}),
            const SizedBox(width: 48),
            _navItem(icon: Icons.notifications_rounded, label: "Notifikasi", onTap: () {}),
            _navItem(icon: Icons.account_circle_rounded, label: "Akun Saya", onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String title) {
    bool isSelected = (selectedFilter == title);
    return GestureDetector(
      onTap: () {
        setState(() { selectedFilter = title; });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : darkTextColor,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: active ? primaryColor : Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: active ? primaryColor : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class JadwalCard extends StatelessWidget {
  final int id;
  final String nama;
  final String alamat;
  final String jam;
  final String status;
  final VoidCallback onLihatLokasi; // 🔥 Ditambahkan parameter baru
  final VoidCallback onMulaiJemput;

  const JadwalCard({
    super.key,
    required this.id,
    required this.nama,
    required this.alamat,
    required this.jam,
    required this.status,
    required this.onLihatLokasi, // 🔥 Ditambahkan ke constructor
    required this.onMulaiJemput,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String displayStatus = status.toLowerCase();

    if (displayStatus == 'selesai' || displayStatus == 'completed') {
      statusColor = Colors.green.shade800;
    } else if (displayStatus == 'proses' || displayStatus == 'on_progress') {
      statusColor = Colors.blue.shade800;
    } else {
      statusColor = Colors.orange.shade800;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: primaryColor.withOpacity(0.08),
                child: const Icon(Icons.person_rounded, color: primaryColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkTextColor, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2.0),
                          child: Icon(Icons.location_on_rounded, size: 16, color: primaryColor),
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Text(alamat, style: const TextStyle(color: greyTextColor, fontSize: 13, fontWeight: FontWeight.w700))),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLihatLokasi, // 🔥 Sekarang memicu fungsi yang dioper dari list view
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    side: const BorderSide(color: primaryColor, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.map_rounded, color: primaryColor, size: 18),
                  label: const Text("LIHAT LOKASI", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.3)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onMulaiJemput,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status.toLowerCase() == 'proses' ? Colors.orange.shade800 : primaryColor,
                    disabledBackgroundColor: Colors.grey.shade200,
                    minimumSize: const Size(0, 50),
                    elevation: (status.toLowerCase() == 'selesai') ? 0 : 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(
                      status.toLowerCase() == 'selesai'
                          ? Icons.check_circle_rounded
                          : (status.toLowerCase() == 'proses' ? Icons.scale_rounded : Icons.local_shipping_rounded),
                      color: status.toLowerCase() == 'selesai' ? Colors.grey.shade500 : Colors.white,
                      size: 18
                  ),
                  label: Text(
                    status.toLowerCase() == 'terjadwal' || status.toLowerCase() == 'pending'
                        ? "MULAI JEMPUT"
                        : (status.toLowerCase() == 'proses' ? "TIMBANG SAMPAH" : "SUDAH SELESAI"),
                    style: TextStyle(
                        color: status.toLowerCase() == 'selesai' ? Colors.grey.shade600 : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.3
                    ),
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