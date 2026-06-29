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
const greyTextColor = Color(0xFF424242);

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

      // 1. Ambil data Dashboard Dasar
      final result = await DashboardKurirService.getDashboard(userId);
      
      // 2. 🔥 WORKAROUND SINKRONISASI: 
      // Jika jadwal di dashboard kosong, coba ambil dari JadwalService (Daftar Tugas)
      if (result['jadwal'] == null || (result['jadwal'] is List && (result['jadwal'] as List).isEmpty)) {
        debugPrint("DASHBOARD KOSONG: Mencoba sinkronisasi dengan JadwalService...");
        final fallbackJadwal = await JadwalService.getJadwalKurir(userId);
        if (fallbackJadwal.isNotEmpty) {
          // Ambil tugas pertama yang belum selesai
          final tugasAktif = fallbackJadwal.firstWhere(
            (j) => j['status'].toString().toLowerCase() != 'selesai',
            orElse: () => null
          );
          if (tugasAktif != null) {
            result['jadwal'] = tugasAktif;
          }
        }
      }

      setState(() {
        dashboardData = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR DASHBOARD: $e");
      setState(() => isLoading = false);
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
        await getDashboard();
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
      debugPrint("ERROR MULAI JEMPUT: $e");
      if (mounted) setState(() => isLoading = false);
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
                      const SizedBox(height: 20),
                      _sectionTitle("Tugas Terdekat Hari Ini"),
                      const SizedBox(height: 10),

                      // Proteksi ekstra pengecekan data jadwal kosong / null
                      dashboardData?['jadwal'] == null ||
                          (dashboardData?['jadwal'] is List && (dashboardData?['jadwal'] as List).isEmpty)
                          ? _buildEmptyTask()
                          : _UrgentTaskItem(
                              jadwalRaw: dashboardData?['jadwal'],
                              onMulaiJemput: (id) => mulaiJemputKurir(id),
                              onRefresh: getDashboard,
                            ),

                      const SizedBox(height: 28),
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
        bottomNavigationBar: _PremiumBottomNav(onRefresh: getDashboard),
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

  Widget _buildEmptyTask() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: cardDecoration(),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 52, color: secondaryColor),
          const SizedBox(height: 12),
          Text(
            "Tidak Ada Jadwal Penjemputan Aktif",
            style: TextStyle(color: darkTextColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            "Semua antrean tugas untuk hari ini telah selesai diproses.",
            style: TextStyle(color: greyTextColor, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
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

class _UrgentTaskItem extends StatelessWidget {
  final dynamic jadwalRaw;
  final Function(int) onMulaiJemput;
  final VoidCallback onRefresh;

  const _UrgentTaskItem({
    required this.jadwalRaw,
    required this.onMulaiJemput,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Unboxing paksa jika data 'jadwal' dikirim berupa Array/List dari endpoint dashboard
    final dynamic jadwal = (jadwalRaw is List && jadwalRaw.isNotEmpty) ? jadwalRaw[0] : jadwalRaw;

    if (jadwal == null || (jadwal is Map && jadwal.isEmpty)) {
      return const SizedBox.shrink();
    }

    String status = (jadwal['status'] ?? 'terjadwal').toString().toLowerCase();
    Color statusColor;
    if (status == 'selesai' || status == 'completed') {
      statusColor = Colors.green.shade800;
    } else if (status == 'proses' || status == 'on_progress' || status == 'dalam_perjalanan') {
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
          // 🔥 HEADER KATEGORI (Badge Kecil di Atas) - Sinkron dengan Daftar Tugas
          _buildCategoryBadge(jadwal),
          const SizedBox(height: 12),
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
                    // 🔥 EKSTRAKSI TINGKAT TINGGI (Disamakan persis dengan halaman Jadwal)
                    Text(
                      _resolveNamaNasabahSamaPersis(jadwal),
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
                        Expanded(
                          child: Text(
                            jadwal['alamat']?.toString() ?? 'Alamat tidak tersedia',
                            style: const TextStyle(color: greyTextColor, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NavigasiKurirPage(initialJadwalData: jadwal),
                      ),
                    );
                  },
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
                  onPressed: () async {
                    final int idJadwal = int.tryParse(jadwal['id']?.toString() ?? '0') ?? 0;
                    final int idNasabah = int.tryParse(jadwal['nasabah_id']?.toString() ?? '') ??
                        int.tryParse(jadwal['user_id']?.toString() ?? '') ?? 0;

                    String st = status.toLowerCase();
                    if (st == 'terjadwal' || st == 'pending') {
                      onMulaiJemput(idJadwal);
                    } else if (st == 'proses' || st == 'on_progress' || st == 'dalam_perjalanan') {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScanBarcodePage(
                            jadwalId: idJadwal,
                            nasabahId: idNasabah,
                          ),
                        ),
                      );
                      if (res == true) onRefresh();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (status == 'proses' || status == 'on_progress' || status == 'dalam_perjalanan') ? Colors.orange.shade800 : primaryColor,
                    disabledBackgroundColor: Colors.grey.shade200,
                    minimumSize: const Size(0, 50),
                    elevation: (status == 'selesai') ? 0 : 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(
                      status == 'selesai'
                          ? Icons.check_circle_rounded
                          : ((status == 'proses' || status == 'on_progress' || status == 'dalam_perjalanan') ? Icons.scale_rounded : Icons.local_shipping_rounded),
                      color: status == 'selesai' ? Colors.grey.shade500 : Colors.white,
                      size: 18
                  ),
                  label: Text(
                    status == 'terjadwal' || status == 'pending'
                        ? "MULAI JEMPUT"
                        : ((status == 'proses' || status == 'on_progress' || status == 'dalam_perjalanan') ? "TIMBANG SAMPAH" : "SUDAH SELESAI"),
                    style: TextStyle(
                        color: status == 'selesai' ? Colors.grey.shade600 : Colors.white,
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

  // 🔥 MENGGUNAKAN POLA PARSING YANG SAMA DENGAN HALAMAN JADWAL
  String _resolveNamaNasabahSamaPersis(dynamic j) {
    if (j == null) return 'Nama Nasabah Tidak Tersedia';

    try {
      final String nama = (
          j['nasabah']?['name'] ??
              j['user']?['name'] ??
              j['nasabah']?['nama'] ??
              j['user']?['nama'] ??
              j['nasabah_name'] ??
              j['user_name'] ??
              j['nama_nasabah'] ??
              j['nama'] ??
              j['name'] ??
              (j['nasabah'] is String ? j['nasabah'] : '')
      ).toString().trim();

      if (nama.isNotEmpty) return nama;
    } catch (_) {}

    return 'Nama Nasabah';
  }

  Widget _buildCategoryBadge(dynamic item) {
    String kategoriJadwal = "Jadwal Khusus";
    Color kategoriColor = Colors.purple.shade700;
    IconData icon = Icons.admin_panel_settings_rounded;

    final String tipe = (item['tipe'] ?? item['kategori'] ?? '').toString().toLowerCase();
    if (tipe == 'rutin' || item['is_rutin'] == true || item['rutin_id'] != null || item['jadwal_rutin_id'] != null) {
      kategoriJadwal = "Jadwal Rutin";
      kategoriColor = primaryColor;
      icon = Icons.sync_rounded;
    } else if (tipe == 'request' || item['request_id'] != null || (item['user_id'] != null && item['jadwal_rutin_id'] == null)) {
      kategoriJadwal = "Request Nasabah";
      kategoriColor = Colors.blue.shade700;
      icon = Icons.person_add_alt_rounded;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kategoriColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kategoriColor.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: kategoriColor),
              const SizedBox(width: 6),
              Text(
                kategoriJadwal.toUpperCase(),
                style: TextStyle(color: kategoriColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
        Text(
          "ID: #${item['id'] ?? '0'}",
          style: const TextStyle(color: greyTextColor, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
class _PremiumBottomNav extends StatelessWidget {
  final VoidCallback onRefresh;
  const _PremiumBottomNav({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 76,
      elevation: 10,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, "Beranda", true, () {}),
          _navItem(Icons.history_rounded, "Riwayat", false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatKurirScreen()))),
          _navItem(Icons.notifications_none_rounded, "Notifikasi", false, () {}),
          _navItem(Icons.person_rounded, "Profil Saya", false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilKurirScreen())).then((_) => onRefresh())),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? primaryColor : greyTextColor, size: 26),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: active ? primaryColor : greyTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
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
              dashboardData?['keterangan_tren'] ?? "Total setoran Anda bulan ini tercatat ${dashboardData?['berat_bulan_ini'] ?? 0} Kg. Teris jaga performa berkendara aman.",
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