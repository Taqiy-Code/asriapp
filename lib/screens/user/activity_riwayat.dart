import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/setor_sampah_service.dart';

const primaryColor = Color(0xFF1E521E);
const secondaryColor = Color(0xFF4CAF50);
const softGreenColor = Color(0xFFE8F5E9);
const backgroundColor = Color(0xFFF9FBF9);
const darkTextColor = Color(0xFF0D240D);
const greyTextColor = Color(0xFF555555);

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  bool isSetor = true;
  DateTime selectedDate = DateTime.now();
  String selectedJenis = "Semua";
  List<dynamic> riwayatRaw = [];
  bool isLoading = true;

  final List<String> jenisSampah = ["Semua", "Plastik", "Metal", "Kertas"];

  @override
  void initState() {
    super.initState();
    loadRiwayat();
  }

  Future<void> loadRiwayat() async {
    try {
      setState(() { isLoading = true; });
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // 🔥 JALUR AMAN: Cek semua tipe data (int maupun string) agar tidak salah baca
      int userId = 0;
      if (prefs.containsKey('user_id')) {
        final rawId = prefs.get('user_id');
        if (rawId is int) {
          userId = rawId;
        } else if (rawId is String) {
          userId = int.tryParse(rawId) ?? 0;
        }
      }

      print("DEBUG MAI RIWAYAT - Mengambil data untuk User ID Valid: $userId");

      // Pastikan data dikirim jika userId tidak bernilai 0
      if (userId != 0) {
        final result = await SetorSampahService.getRiwayat(userId: userId);
        setState(() {
          riwayatRaw = result;
          isLoading = false;
        });
      } else {
        print("DEBUG MAI - Gagal memuat! user_id di memori HP terbaca 0 atau null.");
        setState(() { isLoading = false; });
      }
    } catch (e) {
      print("Error load riwayat data: $e");
      setState(() { isLoading = false; });
    }
  }
  String formatDuitRupiah(dynamic nominalRaw) {
    try {
      int angka = int.parse(nominalRaw.toString().replaceAll(RegExp(r'[^0-9]'), ''));
      return "Rp " + angka.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.'
      );
    } catch (e) {
      return "Rp $nominalRaw";
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat("MMM yyyy").format(selectedDate);

    List<dynamic> riwayatDiFilter = riwayatRaw.where((item) {
      String jenisTx = (item['jenis_transaksi'] ?? 'masuk').toString().toLowerCase();
      bool adalahTarikTunai = jenisTx.contains('keluar') || jenisTx.contains('tarik');
      return isSetor ? !adalahTarikTunai : adalahTarikTunai;
    }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: const Text("Riwayat Transaksi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            decoration: const BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _tabButton(
                        text: "Setor Sampah",
                        icon: Icons.recycling_rounded,
                        isActive: isSetor,
                        onTap: () => setState(() => isSetor = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tabButton(
                        text: "Tarik Tunai",
                        icon: Icons.monetization_on_rounded,
                        isActive: !isSetor,
                        onTap: () => setState(() => isSetor = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _filterTanggal(formattedDate)),
                    const SizedBox(width: 12),
                    Expanded(child: isSetor ? _filterJenis() : _filterDisabledPlaceholder()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 4))
                : RefreshIndicator(
              color: primaryColor,
              onRefresh: loadRiwayat,
              child: riwayatDiFilter.isEmpty
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  const Center(
                    child: Text(
                      "Belum ada catatan aktivitas transaksi.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, color: greyTextColor),
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: riwayatDiFilter.length,
                itemBuilder: (context, index) {
                  final item = riwayatDiFilter[index];

                  String judulKartu = item['judul_dinamis'] ?? 'Setor Sampah';
                  String hargaDuit = (item['nominal'] ?? '0').toString();
                  String tanggalFormatted = (item['tanggal_formatted'] ?? '-').toString();
                  String beratTimbangan = "${item['total_berat'] ?? '0'} Kg";

                  return TransactionCard(
                    title: isSetor ? judulKartu : 'Tarik Tunai Dana',
                    weight: beratTimbangan,
                    status: isSetor ? 'MASUK' : 'KELUAR',
                    price: formatDuitRupiah(hargaDuit),
                    date: tanggalFormatted,
                    isPenarikan: !isSetor,
                    onTap: () {},
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({required String text, required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? primaryColor : Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(text, style: TextStyle(color: isActive ? primaryColor : Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _filterTanggal(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          const Icon(Icons.arrow_drop_down, color: Colors.white),
        ],
      ),
    );
  }

  Widget _filterJenis() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedJenis,
          dropdownColor: primaryColor,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          items: jenisSampah.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: (value) => setState(() => selectedJenis = value!),
        ),
      ),
    );
  }

  Widget _filterDisabledPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: const Text(
        "Semua Mutasi",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}

class TransactionCard extends StatelessWidget {
  final String title;
  final String weight;
  final String status;
  final String price;
  final String date;
  final bool isPenarikan;
  final VoidCallback onTap;

  const TransactionCard({
    super.key,
    required this.title,
    required this.weight,
    required this.status,
    required this.price,
    required this.date,
    this.isPenarikan = false,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = isPenarikan ? Colors.red.shade800 : primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                  radius: 24,
                  backgroundColor: isPenarikan ? Colors.red.shade50 : softGreenColor,
                  child: Icon(
                      isPenarikan ? Icons.payments_rounded : Icons.check_circle_rounded,
                      color: statusColor,
                      size: 24
                  )
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: darkTextColor, letterSpacing: -0.3)
                            )
                        ),
                        const SizedBox(width: 4),
                        Text(date, style: const TextStyle(fontSize: 10, color: greyTextColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12)
                          ),
                          child: Text(
                              status,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.3)
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                                price,
                                style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                    letterSpacing: -0.5
                                )
                            ),
                            if (!isPenarikan) const SizedBox(height: 2),
                            if (!isPenarikan)
                              Text(
                                  weight,
                                  style: const TextStyle(color: greyTextColor, fontSize: 11, fontWeight: FontWeight.bold)
                              ),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}