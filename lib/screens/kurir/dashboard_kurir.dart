import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/dashboard_kurir_service.dart';
import '../../config.dart'; // Tetap terhubung aman dengan AppConfig kamu
import '../login_screen.dart';
import '../kurir/JadwalJemputScreen.dart';
import 'ProfilKurirScreen.dart';
import 'RiwayatKurirScreen.dart';
import 'ScanBarcode.dart';
import 'navigasi_kurir_page.dart'; // Import halaman navigasi rute baru kita

// Palet warna dengan kontras tinggi (Senior-Friendly Theme)
const primaryColor = Color(0xFF1E521E);     // Hijau lebih tua agar tulisan lebih kontras dan jelas
const secondaryColor = Color(0xFF4CAF50);   // Hijau cerah untuk aksen visual
const softGreenColor = Color(0xFFE8F5E9);   // Background komponen yang menyejukkan mata
const backgroundColor = Color(0xFFF9FBF9);  // Putih bersih agar kontras teks maksimal
const darkTextColor = Color(0xFF0D240D);    // Teks super pekat (hampir hitam-hijau) untuk keterbacaan prima
const greyTextColor = Color(0xFF555555);    // Abu-abu yang lebih gelap agar tidak buram bagi mata tua

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

  // 🔥 DIUBAH: Mengembalikan Future agar bisa ditunggu oleh RefreshIndicator
  Future<void> getDashboard() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int userId = prefs.getInt('user_id') ?? 0;

      print("DEBUG MAI - User ID yang terbaca: $userId");

      if (userId == 0) {
        setState(() { isLoading = false; });
        return;
      }

      final result = await DashboardKurirService.getDashboard(userId);

      setState(() {
        dashboardData = result;
        isLoading = false;
      });
    } catch (e) {
      print("DEBUG MAI - Error: $e");
      setState(() { isLoading = false; });
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
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 4)),
      );
    }

    int idJadwalAktif = dashboardData?['jadwal']?['id'] ?? 0;
    List<dynamic> aktivitasTerbaru = dashboardData?['aktivitas_terbaru'] ?? [];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final keluar = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Keluar Aplikasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: darkTextColor)),
            content: const Text("Apakah Anda yakin ingin keluar dari aplikasi ASRI?", style: TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal", style: TextStyle(color: greyTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Ya, Keluar", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (keluar == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        // 🔥 FITUR UTAMA: Membungkus area scroll dengan RefreshIndicator senior-friendly
        body: RefreshIndicator(
          color: primaryColor,
          backgroundColor: Colors.white,
          strokeWidth: 3,
          onRefresh: getDashboard, // Menjalankan ulang fungsi penarikan data dari database Laravel
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(), // Diubah ke AlwaysScrollable agar list kosong tetap bisa ditarik
            ),
            child: Column(
              children: [
                _HeaderSection(onLogout: logout),

                Transform.translate(
                  offset: const Offset(0, -25),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ActiveMissionCard(dashboardData: dashboardData),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _sectionTitle("Ringkasan Hari Ini"),
                      const SizedBox(height: 12),
                      _TodaySummarySection(dashboardData: dashboardData),
                      const SizedBox(height: 32),
                      _sectionTitle("Menu Akses Cepat"),
                      const SizedBox(height: 12),
                      const _QuickActionsRow(),
                      const SizedBox(height: 32),
                      _sectionTitle("Catatan Performa"),
                      const SizedBox(height: 12),
                      _InsightCard(dashboardData: dashboardData),
                      const SizedBox(height: 32),
                      _sectionTitle("Riwayat Setor Terakhir"),
                      const SizedBox(height: 12),

                      aktivitasTerbaru.isEmpty
                          ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                        decoration: cardDecoration(),
                        child: const Center(
                          child: Text(
                            "Belum ada catatan setoran untuk hari ini\n(Tarik ke bawah untuk menyegarkan data)",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: greyTextColor, fontSize: 14, fontWeight: FontWeight.bold, height: 1.4),
                          ),
                        ),
                      )
                          : Column(
                        children: aktivitasTerbaru.map((item) => _ActivityCard(data: item)).toList(),
                      ),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ],
            ),
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
          fontSize: 19,
          fontWeight: FontWeight.w900,
          color: darkTextColor,
          letterSpacing: -0.3,
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
    String totalBeratHariIni = dashboardData?['total_berat_hari_ini']?.toString() ?? '0';
    String totalPendapatanHariIni = dashboardData?['total_pendapatan_hari_ini']?.toString() ?? '0';

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.local_shipping,
            title: "TUGAS HARI INI",
            value: "${dashboardData?['total_pesanan'] ?? 0} Tempat",
            subtitle: "Harus Dikunjungi",
            accentColor: primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.scale_rounded,
            title: "TOTAL SAMPAH",
            value: "$totalBeratHariIni Kg",
            subtitle: "Rp $totalPendapatanHariIni",
            accentColor: Colors.orange.shade800,
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
  final Color accentColor;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 145,
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: greyTextColor, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: darkTextColor, letterSpacing: -0.5)
          ),
          const SizedBox(height: 4),
          Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: accentColor, fontWeight: FontWeight.w800)
          ),
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
          icon: Icons.assignment_rounded,
          title: "Buka Tugas",
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

        // 🔥 INTEGRASI REFRESH: Otomatis menyegarkan data dashboard setelah kembali dari rute navigasi peta
        _MiniActionCard(
          icon: Icons.map_rounded,
          title: "Peta Rute",
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NavigasiKurirPage()),
            );
            if (result == true) {
              final state = context.findAncestorStateOfType<_DashboardKurirState>();
              state?.getDashboard();
            }
          },
        ),
        const _MiniActionCard(icon: Icons.bar_chart_rounded, title: "Lihat Data"),

        _MiniActionCard(
          icon: Icons.assignment_turned_in_rounded,
          title: "Riwayat",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RiwayatKurirScreen()),
            );
          },
        ),
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
        width: 82,
        height: 98,
        decoration: cardDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: darkTextColor)
            ),
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
      height: 78,
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      elevation: 24,
      color: Colors.white,
      shadowColor: primaryColor.withOpacity(0.4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(icon: Icons.home_rounded, label: "Beranda", active: true, onTap: () {}),
          _navItem(
              icon: Icons.assignment_turned_in_rounded,
              label: "Riwayat",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiwayatKurirScreen()),
                );
              }
          ),          const SizedBox(width: 48),
          _navItem(icon: Icons.notifications_rounded, label: "Notifikasi", onTap: () {}),
          _navItem(
            icon: Icons.account_circle_rounded,
            label: "Akun Saya",
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
          Icon(icon, size: 26, color: active ? primaryColor : Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: active ? primaryColor : Colors.grey.shade600,
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
    bool tidakAdaJadwal = (jadwalId == 0);

    return Container(
      height: 72,
      width: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: tidakAdaJadwal ? Colors.transparent : primaryColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        elevation: 0,
        backgroundColor: tidakAdaJadwal ? Colors.grey.shade400 : primaryColor,
        shape: const CircleBorder(),
        onPressed: tidakAdaJadwal ? null : () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ScanBarcodePage(jadwalId: jadwalId)),
          );

          if (result == true) {
            final state = context.findAncestorStateOfType<_DashboardKurirState>();
            state?.getDashboard();
          }
        },
        child: const Icon(Icons.qr_code_scanner_rounded, size: 32, color: Colors.white),
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
      height: 170,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, Color(0xFF2E6B2E)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 16, top: 12),
          child: Align(
            alignment: Alignment.topCenter,
            child: Row(
              children: [
                Hero(
                  tag: 'logo_asri',
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: ClipOval(child: Image.asset("assets/images/logo_asri.png", fit: BoxFit.contain)),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "ASRI",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_rounded, color: Colors.white, size: 26),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 26),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text("Keluar Akun", style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text("Apakah Anda ingin keluar dari akun Anda saat ini?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            onPressed: () {
                              Navigator.pop(context);
                              onLogout();
                            },
                            child: const Text("Keluar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveMissionCard extends StatelessWidget {
  final Map<String, dynamic>? dashboardData;
  const _ActiveMissionCard({required this.dashboardData});

  @override
  Widget build(BuildContext context) {
    final String? fotoPath = dashboardData?['foto'];
    final String cleanBaseUrl = AppConfig.baseUrl.replaceAll('/api', '');

    int totalTugas = dashboardData?['total_pesanan'] ?? 0;
    int tugasSelesai = dashboardData?['total_pesanan_selesai'] ?? 0;
    double progressValue = totalTugas > 0 ? (tugasSelesai  / totalTugas) : 0.0;
    int progressPercent = (progressValue * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              fotoPath != null && fotoPath.isNotEmpty
                  ? Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor.withOpacity(0.2), width: 2.5),
                ),
                child: ClipOval(
                  child: Image.network(
                    "$cleanBaseUrl/$fotoPath",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 32, color: greyTextColor),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: Padding(padding: EdgeInsets.all(14.0), child: CircularProgressIndicator(strokeWidth: 2)));
                    },
                  ),
                ),
              )
                  : CircleAvatar(
                radius: 29,
                backgroundColor: primaryColor.withOpacity(0.08),
                child: const Icon(Icons.person_rounded, size: 32, color: primaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Selamat Bekerja,",
                      style: TextStyle(color: greyTextColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "${dashboardData?['nama_kurir'] ?? 'Kurir'}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: darkTextColor, letterSpacing: -0.3),
                    ),
                  ],
                ),
              ),
              _activeBadge(context),
            ],
          ),
          const SizedBox(height: 24),

          // 🔥 INTEGRASI REFRESH: Ketukan pada judul rute juga otomatis menangkap sinyal kembali untuk disegarkan
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NavigasiKurirPage()),
              );
              if (result == true) {
                final state = context.findAncestorStateOfType<_DashboardKurirState>();
                state?.getDashboard();
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Jadwal Jalan Hari Ini", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkTextColor)),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: primaryColor),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Align(
              alignment: Alignment.centerLeft,
              child: Text("Ada $totalTugas lokasi yang harus dikunjungi", style: const TextStyle(fontSize: 15, color: greyTextColor, fontWeight: FontWeight.w600))
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 12,
              backgroundColor: backgroundColor,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text("$progressPercent% Selesai", style: const TextStyle(fontWeight: FontWeight.w900, color: darkTextColor, fontSize: 15)),
              const Spacer(),
              _startButton(context),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _activeBadge(BuildContext context) {
    final state = context.findAncestorStateOfType<_DashboardKurirState>();
    int idJadwal = state?.dashboardData?['jadwal']?['id'] ?? 0;
    bool tidakAdaTugas = (idJadwal == 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
          color: tidakAdaTugas ? Colors.grey.shade200 : softGreenColor,
          borderRadius: BorderRadius.circular(20)
      ),
      child: Text(
          tidakAdaTugas ? "LIBUR" : "SIAP",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: tidakAdaTugas ? Colors.grey.shade600 : primaryColor)
      ),
    );
  }

  static Widget _startButton(BuildContext context) {
    final state = context.findAncestorStateOfType<_DashboardKurirState>();
    int idJadwal = state?.dashboardData?['jadwal']?['id'] ?? 0;
    bool tidakAdaTugas = (idJadwal == 0);

    return ElevatedButton.icon(
      onPressed: tidakAdaTugas
          ? null
          : () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JadwalJemputScreen()),
        );

        if (result == true) {
          state?.getDashboard();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: tidakAdaTugas ? Colors.grey.shade300 : primaryColor,
        foregroundColor: tidakAdaTugas ? Colors.grey.shade500 : Colors.white,
        elevation: tidakAdaTugas ? 0 : 4,
        shadowColor: primaryColor.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      icon: Icon(
          tidakAdaTugas ? Icons.block_rounded : Icons.play_circle_filled_rounded,
          color: tidakAdaTugas ? Colors.grey.shade500 : Colors.white,
          size: 20
      ),
      label: Text(
        tidakAdaTugas ? "TIADA TUGAS" : "MULAI JEMPUT",
        style: TextStyle(
            color: tidakAdaTugas ? Colors.grey.shade600 : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.5
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
    String beratBulanIni = dashboardData?['berat_bulan_ini']?.toString() ?? '0';
    String keteranganTren = dashboardData?['keterangan_tren'] ?? 'Tetap semangat menjaga kebersihan lingkungan bersama ASRI.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Bulan ini Bapak/Ibu sudah berhasil mengumpulkan total $beratBulanIni Kg sampah lingkungan.\n\n$keteranganTren",
              style: const TextStyle(height: 1.5, color: darkTextColor, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ActivityCard({required this.data});

  @override
  Widget build(BuildContext context) {
    String namaJenis = data['jenis_sampah']?['nama'] ?? 'Sampah';
    String tanggal = data['created_at_formatted'] ?? data['created_at'] ?? '-';
    String totalHarga = "Rp " + (data['total']?.toString() ?? '0');
    String beratSampah = (data['berat']?.toString() ?? '0') + " Kg";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: softGreenColor, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: primaryColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(namaJenis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: darkTextColor)),
                const SizedBox(height: 4),
                Text(tanggal, style: const TextStyle(fontSize: 12, color: greyTextColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(totalHarga, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: primaryColor)),
              const SizedBox(height: 4),
              Text(beratSampah, style: const TextStyle(fontSize: 13, color: darkTextColor, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}