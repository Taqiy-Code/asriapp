import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config.dart';
import '../services/jadwal_service.dart';
import '../login_screen.dart';
import '../kurir/ScanBarcode.dart';

const primary = Color(0xFF2F6B2F);
const secondary = Color(0xFF58C063);
const softGreen = Color(0xFFEAF8EC);
const background = Color(0xFFF7F8FA);
const darkText = Color(0xFF1B1B1B);
const greyText = Color(0xFF7A7A7A);

class JadwalJemputScreen extends StatefulWidget {
  const JadwalJemputScreen({
    super.key,
  });

  @override
  State<JadwalJemputScreen> createState() => _JadwalJemputScreenState();
}

class _JadwalJemputScreenState extends State<JadwalJemputScreen> {
  List<dynamic> jadwalList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getJadwal();
  }

  // ==========================================
  // BERSIH & RINGKAS: Hanya update status ke server
  // ==========================================
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
            content: Text("Status penjemputan: Dalam Proses!"),
            backgroundColor: Colors.blue,
          ),
        );
        getJadwal(); // Cukup refresh data di layar agar tombol mengunci sendiri
      } else {
        print("Gagal memperbarui status");
      }
    } catch (e) {
      print("Error koneksi: $e");
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
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
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          // ================= HEADER =================
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, secondary],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(36),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              "assets/images/logo_asri.png",
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            "ASRI",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 26,
                        ),
                        const SizedBox(width: 14),

                        // ================= LOGOUT =================
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Logout"),
                                content: const Text("Yakin ingin logout?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Batal"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      logout();
                                    },
                                    child: const Text("Logout"),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.logout,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Text(
                      "Jadwal Penjemputan",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${jadwalList.length} jadwal aktif",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ================= BODY =================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // SEARCH
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: primary, size: 28),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Cari alamat / nasabah",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: softGreen,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.tune, color: primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // FILTER
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        FilterChipWidget(title: "Semua", active: true),
                        FilterChipWidget(title: "Hari Ini"),
                        FilterChipWidget(title: "Proses"),
                        FilterChipWidget(title: "Selesai"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // LIST KARTU JADWAL
                  ...jadwalList.map(
                        (jadwal) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: JadwalCard(
                        id: jadwal['id'],
                        nama: jadwal['nasabah']?['name'] ?? 'Tanpa Nama',
                        alamat: jadwal['alamat'] ?? '-',
                        jam: jadwal['tanggal_penjemputan'] ?? '-',
                        status: jadwal['status'] ?? 'pending',
                        statusColor: jadwal['status'] == 'selesai'
                            ? Colors.green
                            : jadwal['status'] == 'proses'
                            ? Colors.blue
                            : Colors.orange,
                        onMulaiJemput: () {
                          mulaiJemputKurir(jadwal['id']);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ================= CUKUP SCAN DI SINI =================
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: () async {
          // Ambil ID jadwal dari item pertama di list yang statusnya aktif
          int idJadwalTerpilih = jadwalList.isNotEmpty ? jadwalList[0]['id'] : 0;

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScanBarcodePage(jadwalId: idJadwalTerpilih),
            ),
          );

          // Jika proses timbang selesai, halaman utama otomatis meremajakan diri
          if (result == true) {
            getJadwal();
          }
        },
        child: const Icon(
          Icons.qr_code_scanner,
          color: Colors.white,
          size: 32,
        ),
      ),

      // BOTTOM NAVBAR
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 74,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            navItem(
              icon: Icons.home,
              label: "Beranda",
              active: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            navItem(
              icon: Icons.history,
              label: "Riwayat",
              active: false,
              onTap: () {},
            ),
            const SizedBox(width: 40),
            navItem(
              icon: Icons.notifications_none,
              label: "Notif",
              active: false,
              onTap: () {},
            ),
            navItem(
              icon: Icons.person_outline,
              label: "Profil",
              active: false,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget navItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: active ? primary : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class FilterChipWidget extends StatelessWidget {
  final String title;
  final bool active;

  const FilterChipWidget({
    super.key,
    required this.title,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: active ? primary : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: TextStyle(
          color: active ? Colors.white : darkText,
          fontWeight: FontWeight.w600,
        ),
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
  final Color statusColor;
  final VoidCallback onMulaiJemput;

  const JadwalCard({
    super.key,
    required this.id,
    required this.nama,
    required this.alamat,
    required this.jam,
    required this.status,
    required this.statusColor,
    required this.onMulaiJemput,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: softGreen,
                child: Icon(Icons.person, color: primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 18, color: primary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(alamat, style: const TextStyle(color: greyText, fontSize: 13))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: primary),
                        const SizedBox(width: 6),
                        Text(jam, style: const TextStyle(color: greyText)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    side: const BorderSide(color: primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  icon: const Icon(Icons.map, color: primary),
                  label: const Text("Lihat Lokasi", style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: status == 'terjadwal' ? onMulaiJemput : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    minimumSize: const Size(0, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  icon: const Icon(Icons.local_shipping, color: Colors.white),
                  label: Text(
                    status == 'terjadwal' ? "Mulai Jemput" : "Dalam Proses",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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