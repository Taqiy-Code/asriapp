import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/setor_sampah_service.dart';
import 'detail_riwayat.dart';

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

  DateTime? selectedDate;
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
      setState(() {
        isLoading = true;
      });
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

      if (userId != 0) {
        final result = await SetorSampahService.getRiwayat(userId: userId);
        setState(() {
          riwayatRaw = result;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error load riwayat data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
                primary: primaryColor,
                onPrimary: Colors.white,
                onSurface: darkTextColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String formatDuitRupiah(dynamic nominalRaw) {
    try {
      int angka =
          int.parse(nominalRaw.toString().replaceAll(RegExp(r'[^0-9]'), ''));
      return "Rp " + NumberFormat.decimalPattern('id').format(angka);
    } catch (e) {
      return "Rp $nominalRaw";
    }
  }

  @override
  Widget build(BuildContext context) {
    String textTombolTanggal = selectedDate != null
        ? DateFormat("dd MMM yyyy").format(selectedDate!)
        : "Pilih Tanggal";

    List<dynamic> riwayatDiFilter = riwayatRaw.where((item) {
      String jenisTx =
          (item['jenis_transaksi'] ?? 'masuk').toString().toLowerCase();
      bool adalahTarikTunai =
          jenisTx.contains('keluar') || jenisTx.contains('tarik');

      bool cocokTab = isSetor ? !adalahTarikTunai : adalahTarikTunai;
      if (!cocokTab) return false;

      if (selectedDate != null) {
        String rawDateStr = item['created_at'] ?? '';
        if (rawDateStr.isNotEmpty) {
          DateTime itemDate = DateTime.parse(rawDateStr);
          if (itemDate.year != selectedDate!.year ||
              itemDate.month != selectedDate!.month ||
              itemDate.day != selectedDate!.day) {
            return false;
          }
        }
      }

      if (isSetor && selectedJenis != "Semua") {
        String judulDinamis =
            (item['judul_dinamis'] ?? '').toString().toLowerCase();
        String kueriFilter = selectedJenis.toLowerCase();
        if (!judulDinamis.contains(kueriFilter)) {
          return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: const Text("Catatan Riwayat",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 22),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            decoration: const BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            child: Column(
              children: [
                Text(
                  "Total berhasil menangani ${riwayatDiFilter.length} transaksi ${isSetor ? 'setoran' : 'tarik tunai'}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _tabButton(
                        text: "Setor Sampah",
                        icon: Icons.recycling_rounded,
                        isActive: isSetor,
                        onTap: () => setState(() {
                          isSetor = true;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tabButton(
                        text: "Tarik Tunai",
                        icon: Icons.monetization_on_rounded,
                        isActive: !isSetor,
                        onTap: () => setState(() {
                          isSetor = false;
                          selectedJenis = "Semua";
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  textTombolTanggal,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isSetor) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _filterJenisContainer(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: primaryColor, strokeWidth: 4))
                : RefreshIndicator(
                    color: primaryColor,
                    onRefresh: loadRiwayat,
                    child: riwayatDiFilter.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.event_busy_rounded,
                                        size: 54,
                                        color: greyTextColor.withOpacity(0.5)),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Tidak ada transaksi ditemukan.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: greyTextColor,
                                          height: 1.4),
                                    ),
                                    if (selectedDate != null ||
                                        selectedJenis != "Semua")
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedDate = null;
                                            selectedJenis = "Semua";
                                          });
                                        },
                                        child: const Text("Reset Filter",
                                            style: TextStyle(
                                                color: primaryColor)),
                                      )
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: riwayatDiFilter.length,
                            itemBuilder: (context, index) {
                              final item = riwayatDiFilter[index];

                              // Mapping data dari database ke UI
                              String judulKartu = (item['nama_kurir'] ?? 'Setoran Sampah').toString();
                              
                              // Jika tarik tunai, ganti judulnya
                              String jenisTx = (item['jenis_transaksi'] ?? 'masuk').toString().toLowerCase();
                              bool adalahTarikTunai = jenisTx.contains('keluar') || jenisTx.contains('tarik');

                              String subjudul = isSetor 
                                ? "Kategori: ${item['judul_dinamis'] ?? '-'}" 
                                : "Penarikan Saldo";
                                
                              String hargaDuit = (item['nominal'] ?? '0').toString();
                              String tanggalFormatted = (item['tanggal_formatted'] ?? '-').toString();

                              return TransactionCard(
                                title: adalahTarikTunai ? 'Tarik Tunai Dana' : judulKartu,
                                subtitle: subjudul,
                                price: formatDuitRupiah(hargaDuit),
                                date: tanggalFormatted,
                                isPenarikan: adalahTarikTunai,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetailRiwayatPage(data: item),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(
      {required String text,
      required IconData icon,
      required bool isActive,
      required VoidCallback onTap}) {
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
            Icon(icon, color: isActive ? primaryColor : Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(text,
                style: TextStyle(
                    color: isActive ? primaryColor : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _filterJenisContainer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedJenis,
          dropdownColor: primaryColor,
          isExpanded: true,
          icon: const Icon(Icons.filter_list_rounded,
              color: Colors.white, size: 20),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          items: jenisSampah
              .map((item) =>
                  DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedJenis = value!;
            });
          },
        ),
      ),
    );
  }
}

class TransactionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String date;
  final bool isPenarikan;
  final VoidCallback onTap;

  const TransactionCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.price,
      required this.date,
      this.isPenarikan = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusColor = isPenarikan ? Colors.red.shade800 : primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isPenarikan ? Colors.red.shade50 : softGreenColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      isPenarikan
                          ? Icons.payments_rounded
                          : Icons.check_circle_rounded,
                      color: statusColor,
                      size: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: darkTextColor)),
                          const SizedBox(height: 4),
                          Text(subtitle,
                              style: const TextStyle(
                                  color: primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(date,
                              style: const TextStyle(
                                  color: greyTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(price,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        )),
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
