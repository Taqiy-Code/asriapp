import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../config.dart';
import 'activity_riwayat.dart'; // File riwayat transaksi milikmu
import 'profile.dart';
import 'setor_sampah.dart';
import 'tarik_tunai.dart';

const primaryColor = Color(0xFF1E521E);
const secondaryColor = Color(0xFF4CAF50);
const softGreenColor = Color(0xFFE8F5E9);
const backgroundColor = Color(0xFFF9FBF9);
const darkTextColor = Color(0xFF0D240D);
const greyTextColor = Color(0xFF555555);

class DashboardScreen extends StatefulWidget {
  final String name;
  final String? foto;

  const DashboardScreen({
    super.key,
    required this.name,
    this.foto,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int saldoNasabah = 0;
  List<dynamic> mutasiList = [];
  bool isLoading = true;
  double totalBeratBulanIni = 0.0;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      setState(() { isLoading = true; });
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // 🔥 JALUR AMAN: Deteksi multi-type user_id agar kebal error parsing
      int userId = 0;
      if (prefs.containsKey('user_id')) {
        final rawId = prefs.get('user_id');
        if (rawId is int) {
          userId = rawId;
        } else if (rawId is String) {
          userId = int.tryParse(rawId) ?? 0;
        }
      }

      print("DEBUG MAI NASABAH - Menembak Dashboard ID: $userId");

      if (userId == 0) {
        setState(() { isLoading = false; });
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/dashboard-nasabah/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            var nasabahObj = data['nasabah'] ?? data['user'] ?? data;

            saldoNasabah = int.tryParse(nasabahObj['saldo'].toString()) ?? 0;
            mutasiList = data['riwayat_mutasi'] ?? [];
            totalBeratBulanIni = double.tryParse(nasabahObj['total_berat_kg'].toString()) ?? 0.0;

            isLoading = false;
          });
        }
      } else {
        setState(() { isLoading = false; });
      }
    } catch (e) {
      print("ERROR DASHBOARD NASABAH: $e");
      setState(() { isLoading = false; });
    }
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    bool? keluar = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Konfirmasi"),
          content: const Text("Apakah yakin ingin keluar?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Tidak"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Ya"),
            ),
          ],
        );
      },
    );
    return keluar ?? false;
  }

  String formatRupiah(int angka) {
    return "Rp " + angka.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.'
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        bool keluar = await _showExitDialog(context);
        if (keluar) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        bottomNavigationBar: _buildBottomNav(context),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 4))
              : RefreshIndicator(
            color: primaryColor,
            onRefresh: fetchDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ================= HEADER & PROFILE CARD =================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 30),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, Color(0xFF2E6B2E)],
                      ),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Basayan Bestari",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 26),
                              onPressed: () async {
                                bool keluar = await _showExitDialog(context);
                                if (keluar) {
                                  Navigator.pushReplacementNamed(context, '/login');
                                }
                              },
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: softGreenColor,
                                backgroundImage: widget.foto != null ? NetworkImage(widget.foto!) : null,
                                child: widget.foto == null ? const Icon(Icons.person_rounded, size: 36, color: primaryColor) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Halo, ${widget.name}!",
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkTextColor, letterSpacing: -0.3),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "Terima kasih sudah menjaga bumi.\nYuk, cek isi tabungan dompetmu!",
                                      style: TextStyle(fontSize: 12, color: greyTextColor, fontWeight: FontWeight.w600),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ================= RINGKASAN SALDO & BERAT =================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Ringkasan Dompet",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: darkTextColor),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    color: Colors.white,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.account_balance_wallet_rounded, color: primaryColor, size: 30),
                                        const SizedBox(height: 6),
                                        Text(
                                          formatRupiah(saldoNasabah),
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: primaryColor),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text("Saldo Anda", style: TextStyle(fontSize: 12, color: greyTextColor, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    color: softGreenColor,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.scale_rounded, color: primaryColor, size: 30),
                                        const SizedBox(height: 6),
                                        Text(
                                          "$totalBeratBulanIni Kg",
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: primaryColor),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text("Total Sampah", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ================= MENU UTAMA =================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Menu Utama", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: darkTextColor)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 🔥 FIX SINKRONISASI ROUTE: Menembak halaman riwayatmu yang asli
                            _menuItem(Icons.receipt_long_rounded, "Riwayat\nTransaksi", () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatPage()));
                            }),
                            _menuItem(Icons.delete_sweep_rounded, "Setor\nSampah", () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const SetorSampahScreen()));
                            }),
                            _menuItem(Icons.monetization_on_rounded, "Tarik\nTunai", () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const TarikTunaiPage()));
                            }),
                            _menuItem(Icons.support_agent_rounded, "Bantuan", () {}),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ================= LIST MUTASI SALDO =================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Riwayat Aktivitas Dompet",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: darkTextColor),
                        ),
                        const SizedBox(height: 16),

                        mutasiList.isEmpty
                            ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text("Belum ada mutasi keuangan.", style: TextStyle(color: greyTextColor, fontWeight: FontWeight.w600)),
                          ),
                        )
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: mutasiList.length > 5 ? 5 : mutasiList.length,
                          itemBuilder: (context, index) {
                            final item = mutasiList[index];

                            String jenisTx = (item['jenis_transaksi'] ?? 'masuk').toString().toLowerCase();
                            bool isUangMasuk = jenisTx == 'masuk';

                            int nominal = int.tryParse(item['nominal'].toString()) ?? 0;
                            String judulKartu = item['judul_dinamis'] ?? (isUangMasuk ? "Uang Masuk (Setor Sampah)" : "Uang Keluar (Tarik Tunai)");

                            return _historyItem(
                              judulKartu,
                              item['tanggal_formatted'] ?? '-',
                              "${isUangMasuk ? '+' : '-'} ${formatRupiah(nominal)}",
                              isUangMasuk ? Colors.green.shade800 : Colors.red.shade800,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(icon, color: primaryColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: darkTextColor, height: 1.3),
          )
        ],
      ),
    );
  }

  Widget _historyItem(String type, String date, String price, Color warnaHarga) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: darkTextColor), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(fontSize: 12, color: greyTextColor, fontWeight: FontWeight.w600))
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: warnaHarga),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      selectedItemColor: primaryColor,
      unselectedItemColor: greyTextColor,
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      onTap: (index) {
        if (index == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatPage()));
        } else if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SetorSampahScreen()));
        } else if (index == 4) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const profile_page()));
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Beranda"),
        BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: "Riwayat"),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: "Mulai Setor"),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: "Notifikasi"),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profil"),
      ],
    );
  }
}