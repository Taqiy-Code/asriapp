import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/dashboard_kurir_service.dart';
import '../services/jadwal_service.dart';
import '../../config.dart';
import '../login_screen.dart';
import '../kurir/JadwalJemputScreen.dart';
import 'ProfilKurirScreen.dart';
import 'RiwayatKurirScreen.dart';
import 'ScanBarcode.dart';
import 'navigasi_kurir_page.dart';
import '../user/aduan_page.dart';

// Palet Warna Kontras Tinggi & Profesional
const primaryColor = Color(0xFF154015);
const secondaryColor = Color(0xFF2E7D32);
const softGreenColor = Color(0xFFF0F7F0);
const backgroundColor = Color(0xFFF6F8F6);
const darkTextColor = Color(0xFF0A1A0A);
const greyTextColor = Color(0xFF555555);

class DashboardKurir extends StatefulWidget {
  const DashboardKurir({super.key});

  @override
  State<DashboardKurir> createState() => _DashboardKurirState();
}

class _DashboardKurirState extends State<DashboardKurir> {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;

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

  Future<void> getDashboard() async {
    try {
      setState(() => isLoading = true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int userId = 0;
      if (prefs.containsKey('user_id')) {
        final rawId = prefs.get('user_id');
        if (rawId is int) {
          userId = rawId;
        } else if (rawId is String) {
          userId = int.tryParse(rawId) ?? 0;
        }
      }

      if (userId == 0) {
        setState(() => isLoading = false);
        return;
      }

      final result = await DashboardKurirService.getDashboard(userId);

      setState(() {
        dashboardData = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR DASHBOARD: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    getDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: false,
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 4))
            : RefreshIndicator(
          color: primaryColor,
          onRefresh: getDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _sectionTitle("Ringkasan Performa Kerja"),
                      const SizedBox(height: 10),
                      _TodaySummarySection(dashboardData: dashboardData),

                      const SizedBox(height: 28),
                      _sectionTitle("Menu Akses Cepat"),
                      const SizedBox(height: 10),
                      const _QuickActionsLayout(),

                      const SizedBox(height: 28),
                      _sectionTitle("Catatan & Evaluasi"),
                      const SizedBox(height: 10),
                      _InsightCard(dashboardData: dashboardData),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 🔥 1. POSISI TOMBOL DI SET TEPAT DI TENGAH COAKAN NAVBAR (DOCKING CENTER)
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // 🔥 2. DESAIN UTUH FAB DENGAN GRADASI GLOSSY & GLOW SHADOW MEWAH
        floatingActionButton: Container(
          height: 72,
          width: 72,
          margin: const EdgeInsets.only(top: 12), // Memberikan space gantung proporsional di atas notch
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: secondaryColor.withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ScanBarcodePage(
                    jadwalId: 0,
                    nasabahId: 0,
                  ),
                ),
              );
              if (res == true) getDashboard();
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            highlightElevation: 0,
            shape: const CircleBorder(),
            child: Ink(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    secondaryColor,
                    primaryColor.withOpacity(0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(color: Colors.white, width: 2), // Ring Border Putih Kontras
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ),

        // 🔥 3. NAVBAR DENGAN LENGKUNGAN SEMPURNA MENGIKUTI FAB GRADASI
        bottomNavigationBar: BottomAppBar(
          clipBehavior: Clip.antiAlias,
          notchMargin: 8.0,
          shape: const CircularNotchedRectangle(),
          color: Colors.white,
          elevation: 16,
          padding: EdgeInsets.zero,
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sisi Kiri (Beranda & Riwayat)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home_rounded, "Beranda", true, () {}),
                    _buildNavItem(Icons.history_rounded, "Riwayat", false, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatKurirScreen()));
                    }),
                  ],
                ),
              ),

              // Spacer pemisah tengah (menghindari tabrakan dengan bulatan tombol glow)
              const SizedBox(width: 60),

              // Sisi Kanan (Notifikasi & Profil)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.notifications_none_rounded, "Notifikasi", false, () {}),
                    _buildNavItem(Icons.person_rounded, "Profil", false, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilKurirScreen())).then((_) => getDashboard());
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
              icon,
              color: active ? primaryColor : greyTextColor.withOpacity(0.7),
              size: 24
          ),
          const SizedBox(height: 3),
          Text(
              label,
              style: TextStyle(
                color: active ? primaryColor : greyTextColor,
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              )
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 190,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          padding: const EdgeInsets.only(top: 50, left: 20, right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ASRI SYSTEM", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  SizedBox(height: 2),
                  Text("Manajemen Penjemputan Kurir", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 26),
                tooltip: "Keluar Akun",
                onPressed: _showLogoutConfirm,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 115, left: 16, right: 16),
          child: _ActiveMissionCard(dashboardData: dashboardData),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkTextColor, letterSpacing: -0.3),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Konfirmasi Keluar", style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
        content: const Text("Apakah Anda yakin ingin keluar dan mengakhiri sesi halaman kerja?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: greyTextColor, fontSize: 15, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: logout,
            child: const Text("Keluar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() async {
    final keluar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Tutup Aplikasi", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Apakah Anda yakin ingin keluar dari Aplikasi ASRI?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Kembali")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya, Tutup", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (keluar == true) Navigator.of(context).pop();
  }
}

class _ActiveMissionCard extends StatelessWidget {
  final Map<String, dynamic>? dashboardData;
  const _ActiveMissionCard({required this.dashboardData});

  @override
  Widget build(BuildContext context) {
    final String cleanBaseUrl = AppConfig.baseUrl.replaceAll('/api', '');
    int total = int.tryParse(dashboardData?['total_pesanan']?.toString() ?? '0') ?? 0;
    int selesai = int.tryParse(dashboardData?['total_pesanan_selesai']?.toString() ?? '0') ?? 0;
    double progress = total > 0 ? (selesai / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: softGreenColor,
                backgroundImage: dashboardData?['foto'] != null ? NetworkImage("$cleanBaseUrl/${dashboardData?['foto']}") : null,
                child: dashboardData?['foto'] == null ? const Icon(Icons.account_box_rounded, size: 36, color: primaryColor) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Akun Petugas Kurir", style: TextStyle(color: greyTextColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      "${dashboardData?['nama_kurir'] ?? 'Petugas Lapangan'}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkTextColor, letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6), border: Border.all(color: secondaryColor, width: 1)),
                child: const Text("AKTIF", style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w900)),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Progres Kerja Hari Ini", style: TextStyle(fontWeight: FontWeight.w700, color: darkTextColor, fontSize: 14)),
              Text("$selesai Selesai dari $total Lokasi", style: const TextStyle(fontWeight: FontWeight.w900, color: primaryColor, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 14,
              backgroundColor: Colors.grey.shade100,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySummarySection extends StatelessWidget {
  final Map<String, dynamic>? dashboardData;
  const _TodaySummarySection({required this.dashboardData});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryBox(
            title: "TOTAL ALAMAT",
            value: "${dashboardData?['total_pesanan'] ?? 0}",
            unit: "Titik Jemput",
            icon: Icons.local_shipping_rounded,
            color: primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryBox(
            title: "BERAT TERTINJAU",
            value: "${dashboardData?['total_berat_hari_ini'] ?? 0}",
            unit: "Kilogram (Kg)",
            icon: Icons.scale_rounded,
            color: Colors.orange.shade900,
          ),
        ),
      ],
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title, value, unit;
  final IconData icon;
  final Color color;

  const _SummaryBox({required this.title, required this.value, required this.unit, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: greyTextColor, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            verticalDirection: VerticalDirection.down,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: darkTextColor, height: 1.0)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(unit, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsLayout extends StatelessWidget {
  const _QuickActionsLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _largeMenuButton(context, Icons.assignment_rounded, "Daftar Tugas", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JadwalJemputScreen())))),
            const SizedBox(width: 12),
            Expanded(child: _largeMenuButton(context, Icons.map_rounded, "Peta Rute", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NavigasiKurirPage())))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _largeMenuButton(context, Icons.history_rounded, "Riwayat Kerja", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatKurirScreen())))),
            const SizedBox(width: 12),
            Expanded(child: _largeMenuButton(context, Icons.support_agent_rounded, "Pusat Aduan", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AduanPage())))),
          ],
        ),
      ],
    );
  }

  Widget _largeMenuButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: cardDecoration().copyWith(
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primaryColor, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkTextColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Map<String, dynamic>? dashboardData;
  const _InsightCard({this.dashboardData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.analytics_rounded, color: primaryColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              dashboardData?['keterangan_tren'] ?? "Total setoran Anda bulan ini tercatat ${dashboardData?['berat_bulan_ini'] ?? 0} Kg. Terus jaga performa berkendara aman.",
              style: const TextStyle(color: darkTextColor, fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
  );
}