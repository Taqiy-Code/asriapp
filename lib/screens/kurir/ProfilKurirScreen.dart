import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:asriapp/config.dart';
import '../login_screen.dart';
import 'ScanBarcode.dart';

const primary = Color(0xFF2F6B2F);
const secondary = Color(0xFF58C063);
const softGreen = Color(0xFFEAF8EC);
const background = Color(0xFFF7F8FA);
const darkText = Color(0xFF1B1B1B);
const greyText = Color(0xFF7A7A7A);

class ProfilKurirScreen extends StatefulWidget {
  const ProfilKurirScreen({super.key});

  @override
  State<ProfilKurirScreen> createState() => _ProfilKurirScreenState();
}

class _ProfilKurirScreenState extends State<ProfilKurirScreen> {
  String namaKurir = 'Memuat...';
  String emailKurir = '-';
  String noHpKurir = '-';
  String alamatKurir = '-';
  String? fotoPath;
  int idJadwalAktif = 0; // Tambahkan variabel untuk menampung ID jadwal
  bool isLoading = true;

  String baseUrlServer = "http://192.168.100.48:8000";

  @override
  void initState() {
    super.initState();
    getProfilData();
  }

  Future<void> getProfilData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int userId = prefs.getInt('user_id') ?? 0;

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/dashboard-kurir/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Pengaman relasi data dari API Laravel
        final kurir = data['jadwal']?['kurir'];

        setState(() {
          namaKurir = data['nama_kurir'] ?? 'Kurir ASRI';
          emailKurir = kurir?['email'] ?? '-';
          noHpKurir = kurir?['no_hp'] ?? '-';
          alamatKurir = kurir?['alamat'] ?? '-';
          fotoPath = kurir?['foto'];
          // Ambil ID jadwal aktif jika ada untuk modal cadangan scanner
          idJadwalAktif = data['jadwal']?['id'] ?? 0;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    return Scaffold(
      backgroundColor: background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= HEADER PROFILE (GRADIENT) =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, secondary],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: ClipOval(
                          child: fotoPath != null && fotoPath!.isNotEmpty
                              ? Image.network(
                            "$baseUrlServer/$fotoPath",
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, size: 50, color: Colors.white),
                          )
                              : const Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    namaKurir,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Petugas Kurir Lapangan",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= INFO CARDS =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Informasi Pribadi",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.03),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(Icons.email_outlined, "Email", emailKurir),
                        const Divider(height: 24),
                        _buildInfoTile(Icons.phone_android_outlined, "Nomor HP", noHpKurir),
                        const Divider(height: 24),
                        _buildInfoTile(Icons.location_on_outlined, "Alamat Tugas", alamatKurir),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ================= TOMBOL LOGOUT =================
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        side: BorderSide(color: Colors.red.shade100),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Logout"),
                            content: const Text("Yakin ingin keluar akun?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Batal"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () {
                                  Navigator.pop(context);
                                  logout();
                                },
                                child: const Text("Logout", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        "Keluar Akun",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),

      // ================= NAVIGATION DOCKED ELEMENTS =================
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        onPressed: () {
          // SINKRON: Lempar variabel idJadwalAktif yang didapat dari API
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScanBarcodePage(jadwalId: idJadwalAktif),
            ),
          );
        },
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 74,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              icon: Icons.home_outlined,
              label: "Beranda",
              active: false,
              onTap: () => Navigator.pop(context),
            ),
            _navItem(
              icon: Icons.history,
              label: "Riwayat",
              active: false,
              onTap: () {},
            ),
            const SizedBox(width: 40),
            _navItem(
              icon: Icons.notifications_none,
              label: "Notif",
              active: false,
              onTap: () {},
            ),
            _navItem(
              icon: Icons.person,
              label: "Profil",
              active: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: softGreen, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: greyText, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: darkText, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _navItem({
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
          Icon(icon, color: active ? primary : Colors.grey),
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