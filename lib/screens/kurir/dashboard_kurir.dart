import 'package:flutter/material.dart';
import '../services/dashboard_kurir_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_screen.dart';
import '../kurir/JadwalJemputScreen.dart';
import 'ProfilKurirScreen.dart';
import 'ScanBarcode.dart';

const primary = Color(0xFF2F6B2F);
const secondary = Color(0xFF58C063);
const softGreen = Color(0xFFEAF8EC);
const background = Color(0xFFF7F8FA);
const darkText = Color(0xFF1B1B1B);
const greyText = Color(0xFF7A7A7A);

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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int userId = prefs.getInt('user_id') ?? 0;
      final result = await DashboardKurirService.getDashboard(userId);

      setState(() {
        dashboardData = result;
        isLoading = false;
      });
      print(dashboardData);
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getDashboard();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    // Ambil ID jadwal aktif dari payload API Laravel kamu
    int idJadwalAktif = dashboardData?['jadwal']?['id'] ?? 0;

    // Ambil list riwayat aktivitas dari database jika ada di JSON, jika tidak ada fallback ke list kosong []
    List<dynamic> aktivitasTerbaru = dashboardData?['aktivitas_terbaru'] ?? [];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final keluar = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Keluar Aplikasi"),
            content: const Text("Yakin ingin keluar aplikasi?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Keluar"),
              ),
            ],
          ),
        );

        if (keluar == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _HeaderSection(onLogout: logout),

              Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ActiveMissionCard(dashboardData: dashboardData),
                ),
              ),

              Transform.translate(
                offset: const Offset(0, -15),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _sectionTitle("Ringkasan Hari Ini"),
                      const SizedBox(height: 16),
                      _TodaySummarySection(dashboardData: dashboardData),
                      const SizedBox(height: 28),
                      _sectionTitle("Akses Cepat"),
                      const SizedBox(height: 16),
                      const _QuickActionsRow(),
                      const SizedBox(height: 28),
                      _sectionTitle("Performa Bulan Ini"),
                      const SizedBox(height: 16),
                      _InsightCard(dashboardData: dashboardData),
                      const SizedBox(height: 28),
                      _sectionTitle("Aktivitas Terbaru"),
                      const SizedBox(height: 16),

                      // DInamis: Jika database memiliki data riwayat, tampilkan. Jika kosong, beri info.
                      aktivitasTerbaru.isEmpty
                          ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: cardDecoration(),
                        child: const Center(
                          child: Text(
                            "Belum ada aktivitas transaksi hari ini",
                            style: TextStyle(color: greyText, fontSize: 13),
                          ),
                        ),
                      )
                          : Column(
                        children: aktivitasTerbaru.map((item) => _ActivityCard(data: item)).toList(),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _ScanFab(jadwalId: idJadwalAktif),
        bottomNavigationBar: _PremiumBottomNav(onRefresh: getDashboard),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
      ),
    );
  }
}

class _TodaySummarySection extends StatelessWidget {
  final Map<String, dynamic>? dashboardData;
  const _TodaySummarySection({required this.dashboardData});

  @override
  Widget build(BuildContext context) {
    // Menghubungkan variabel total hasil timbangan & pendapatan dari database jika tersedia di API
    String totalBeratHariIni = dashboardData?['total_berat_hari_ini']?.toString() ?? '0';
    String totalPendapatanHariIni = dashboardData?['total_pendapatan_hari_ini']?.toString() ?? '0';

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.local_shipping,
            title: "Tugas Hari Ini",
            value: "${dashboardData?['total_pesanan'] ?? 0} Lokasi",
            subtitle: "Kelola Jemputan",
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _SummaryCard(
            icon: Icons.recycling,
            title: "Hasil Hari Ini",
            value: "$totalBeratHariIni Kg",
            subtitle: "Rp $totalPendapatanHariIni",
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: primary),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 11, color: greyText)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MiniActionCard(
          icon: Icons.list_alt_outlined,
          title: "Daftar Jemput",
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JadwalJemputScreen()),
            );
            if (result == true) {
              final state = context.findAncestorStateOfType<_DashboardKurirState>();
              state?.getDashboard();
            }
          },
        ),
        const _MiniActionCard(icon: Icons.map_outlined, title: "Map"),
        const _MiniActionCard(icon: Icons.delete_outline, title: "Data"),
        const _MiniActionCard(icon: Icons.history, title: "Riwayat"),
      ],
    );
  }
}

class _MiniActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _MiniActionCard({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: softGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: primary),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _PremiumBottomNav extends StatelessWidget {
  final VoidCallback onRefresh;
  const _PremiumBottomNav({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 72,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 12,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            icon: Icons.home,
            label: "Beranda",
            active: true,
            onTap: () {},
          ),
          _navItem(
            icon: Icons.history,
            label: "Riwayat",
            onTap: () {},
          ),
          const SizedBox(width: 40),
          _navItem(
            icon: Icons.notifications_none,
            label: "Notif",
            onTap: () {},
          ),
          _navItem(
            icon: Icons.person_outline,
            label: "Profil",
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilKurirScreen()),
              );
              onRefresh();
            },
          ),
        ],
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
          Icon(icon, size: 22, color: active ? primary : Colors.grey),
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

class _ScanFab extends StatelessWidget {
  final int jadwalId;
  const _ScanFab({required this.jadwalId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      width: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        elevation: 0,
        backgroundColor: primary,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ScanBarcodePage(jadwalId: jadwalId)),
          );

          if (result == true) {
            final state = context.findAncestorStateOfType<_DashboardKurirState>();
            state?.getDashboard();
          }
        },
        child: const Icon(Icons.qr_code_scanner, size: 30, color: Colors.white),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final VoidCallback onLogout;
  const _HeaderSection({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 165,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, secondary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
          child: Align(
            alignment: Alignment.topCenter,
            child: Row(
              children: [
                _logo(),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "ASRI",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: Icon(Icons.notifications_none, color: Colors.white, size: 24),
                ),
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
                              onLogout();
                            },
                            child: const Text("Logout"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(Icons.logout, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 12)],
      ),
      child: ClipOval(
        child: Image.asset("assets/images/logo_asri.png", fit: BoxFit.cover),
      ),
    );
  }
}

class _ActiveMissionCard extends StatelessWidget {
  final Map<String, dynamic>? dashboardData;
  const _ActiveMissionCard({required this.dashboardData});

  @override
  Widget build(BuildContext context) {
    final String? fotoPath = dashboardData?['jadwal']?['kurir']?['foto'];
    const String baseUrlServer = "http://192.168.100.48:8000";

    int totalTugas = dashboardData?['total_pesanan'] ?? 0;
    // Ambil data pesanan selesai dari API untuk hitung progress bar linier secara akurat
    int tugasSelesai = dashboardData?['total_pesanan_selesai'] ?? 0;
    double progressValue = totalTugas > 0 ? (tugasSelesai / totalTugas) : 0.0;
    int progressPercent = (progressValue * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              fotoPath != null && fotoPath.isNotEmpty
                  ? Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
                child: ClipOval(
                  child: Image.network(
                    "$baseUrlServer/$fotoPath",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, size: 28, color: Colors.white);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(14.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
              )
                  : const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Halo, ${dashboardData?['nama_kurir'] ?? 'Kurir'} 👋",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text("Kurir Aktif • Online", style: TextStyle(color: greyText, fontSize: 12)),
                  ],
                ),
              ),
              _activeBadge(),
            ],
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Jemputan Hari Ini",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("$totalTugas tugas aktif"),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              color: primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                "$progressPercent% selesai",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _startButton(context),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _activeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: softGreen, borderRadius: BorderRadius.circular(20)),
      child: const Text(
        "AKTIF",
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primary),
      ),
    );
  }

  static Widget _startButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JadwalJemputScreen()),
        );

        if (result == true) {
          final state = context.findAncestorStateOfType<_DashboardKurirState>();
          state?.getDashboard();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      icon: const Icon(Icons.local_shipping, color: Colors.white),
      label: const Text(
        "MULAI",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Map<String, dynamic>? dashboardData;
  const _InsightCard({this.dashboardData});

  @override
  Widget build(BuildContext context) {
    // Membaca data performa bulanan secara dinamis dari database jika dikirim oleh API
    String beratBulanIni = dashboardData?['berat_bulan_ini']?.toString() ?? '0';
    String keteranganTren = dashboardData?['keterangan_tren'] ?? 'Tetap semangat mengumpulkan sampah lingkungan.';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Anda mengumpulkan $beratBulanIni Kg sampah bulan ini.\n$keteranganTren",
              style: const TextStyle(height: 1.6),
            ),
          ),
          const Icon(Icons.trending_up, size: 44, color: primary),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  // Menggunakan tipe data Map<String, dynamic> dinamis bawaan database, bukan dummy model lagi
  final Map<String, dynamic> data;
  const _ActivityCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // Pemetaan key disesuaikan dengan skema tabel database setor_sampah / jenis_sampah kamu
    String namaJenis = data['jenis_sampah']?['nama'] ?? 'Sampah';
    String tanggal = data['created_at_formatted'] ?? data['created_at'] ?? '-';
    String totalHarga = "Rp " + (data['total']?.toString() ?? '0');
    String beratSampah = (data['berat']?.toString() ?? '0') + " Kg";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: softGreen, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.recycling, color: primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        namaJenis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _statusChip(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(tanggal, style: const TextStyle(fontSize: 12, color: greyText)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalHarga,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 4),
              Text(beratSampah, style: const TextStyle(fontSize: 12, color: greyText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: softGreen, borderRadius: BorderRadius.circular(20)),
      child: const Text(
        "Selesai",
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary),
      ),
    );
  }
}

BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.04),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );
}