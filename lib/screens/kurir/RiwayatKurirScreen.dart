import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../config.dart';
import 'DetailRiwayatScreen.dart';

// Palet warna kontras tinggi (Senior-Friendly Theme Basayan Bestari)
const primaryColor = Color(0xFF1E521E);
const secondaryColor = Color(0xFF4CAF50);
const softGreenColor = Color(0xFFE8F5E9);
const backgroundColor = Color(0xFFF9FBF9);
const darkTextColor = Color(0xFF0D240D);
const greyTextColor = Color(0xFF555555);

class RiwayatKurirScreen extends StatefulWidget {
  const RiwayatKurirScreen({super.key});

  @override
  State<RiwayatKurirScreen> createState() => _RiwayatKurirScreenState();
}

class _RiwayatKurirScreenState extends State<RiwayatKurirScreen> {
  List<dynamic> riwayatList = [];
  bool isLoading = true;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    getRiwayatData();
  }

  // ========================================================
  // AMBIL DATA RIWAYAT SETORAN DARI DATABASE LARAVEL
  // ========================================================
  Future<void> getRiwayatData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int userId = prefs.getInt('user_id') ?? 0;

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/riwayat-kurir/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print("DEBUG DATA RIWAYAT UTUH DARI LARAVEL: $data");

        setState(() {
          if (data is List) {
            riwayatList = data;
          } else if (data is Map) {
            riwayatList = data['riwayat'] ?? data['aktivitas_terbaru'] ?? [];
          } else {
            riwayatList = [];
          }
          isLoading = false;
        });
      } else {
        print("Gagal mengambil data riwayat. Status Code: ${response.statusCode}");
        setState(() { isLoading = false; });
      }
    } catch (e) {
      print("DEBUG MAI RIWAYAT ERROR: $e");
      setState(() { isLoading = false; });
    }
  }

  // FUNGSI MEMBUKA KALENDER DATE PICKER
  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
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
              onSurface: darkTextColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
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

    // LOGIKA FILTERING: Menyaring list data berdasarkan tanggal
    List<dynamic> filteredRiwayat = riwayatList.where((item) {
      if (selectedDate == null) return true;

      String rawDate = item['created_at'] ?? '';
      if (rawDate.isEmpty) return false;

      try {
        DateTime itemDate = DateTime.parse(rawDate);
        return itemDate.year == selectedDate!.year &&
            itemDate.month == selectedDate!.month &&
            itemDate.day == selectedDate!.day;
      } catch (e) {
        return false;
      }
    }).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // HEADER RIWAYAT
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
                          "Catatan Riwayat",
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
                        icon: Icon(
                          selectedDate == null ? Icons.calendar_month_rounded : Icons.filter_alt_rounded,
                          color: selectedDate == null ? Colors.white : Colors.orangeAccent,
                          size: 28,
                        ),
                        onPressed: () => _pilihTanggal(context),
                      ),
                    ],
                  ),

                  if (selectedDate != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 14, top: 8, bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade800,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  "Tanggal: ${DateFormat('dd MMM yyyy').format(selectedDate!)}",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() { selectedDate = null; });
                                  },
                                  child: const Icon(Icons.cancel_rounded, color: Colors.white, size: 16),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      selectedDate == null
                          ? "Total berhasil menangani ${filteredRiwayat.length} transaksi setoran"
                          : "Ditemukan ${filteredRiwayat.length} transaksi pada tanggal terpilih",
                      textAlign: TextAlign.center,
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

          const SizedBox(height: 16),

          // DAFTAR RIWAYAT TRANSAKSI DISARING
          Expanded(
            child: filteredRiwayat.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        selectedDate == null ? Icons.assignment_turned_in_rounded : Icons.search_off_rounded,
                        size: 72,
                        color: Colors.grey.shade300
                    ),
                    const SizedBox(height: 16),
                    Text(
                      selectedDate == null ? "Belum Ada Riwayat Setoran" : "Tidak Ada Transaksi",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkTextColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedDate == null
                          ? "Semua transaksi setor sampah yang Anda timbang hari ini akan tercatat di sini."
                          : "Tidak ditemukan catatan penimbangan kurir untuk tanggal ini di database.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: greyTextColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
                : RefreshIndicator(
              color: primaryColor,
              onRefresh: getRiwayatData,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                itemCount: filteredRiwayat.length,
                itemBuilder: (context, index) {
                  final Map<String, dynamic> item = Map<String, dynamic>.from(filteredRiwayat[index]);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailRiwayatScreen(data: item),
                        ),
                      );
                    },
                    child: _buildRiwayatCard(item),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // WIDGET KARTU RIWAYAT DENGAN PARSING KATEGORI MULTI-ITEM
  // ========================================================
  Widget _buildRiwayatCard(Map<String, dynamic> data) {
    String namaNasabah = data['nasabah']?['name'] ?? 'Nasabah ASRI';
    String rawDate = data['created_at'] ?? '';
    String tanggal = '-';

    // Parsing tanggal kiriman API agar lebih human-readable
    if (rawDate.isNotEmpty) {
      try {
        DateTime parsedDate = DateTime.parse(rawDate);
        tanggal = DateFormat('dd MMM yyyy, HH:mm').format(parsedDate) + " WIB";
      } catch (e) {
        tanggal = rawDate;
      }
    }

    // Formatter Rupiah Lokalan
    String totalHarga = "Rp " + data['total'].toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.'
    );

    // 🛠️ LOGIKA BARU KATEGORI MULTI-ITEM: SAMPAH PERTAMA + LAINNYA
    List<dynamic> details = data['details'] ?? [];
    String namaJenisTampil = "Sampah Umum";

    if (details.isNotEmpty) {
      // Ambil nama dari jenis_sampah milik baris index ke-0
      String sampahPertama = details[0]['jenis_sampah']?['nama'] ?? 'Sampah';

      if (details.length > 1) {
        namaJenisTampil = "$sampahPertama + ${details.length - 1} lainnya";
      } else {
        namaJenisTampil = sampahPertama;
      }
    } else if (data['jenis_sampah'] != null) {
      // Fallback aman jika data penimbangan lama (single item) yang dibaca
      namaJenisTampil = data['jenis_sampah']['nama'] ?? 'Sampah';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: softGreenColor, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: primaryColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaNasabah,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: darkTextColor, letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                // Menampilkan Kategori Multi-Item Rapi
                Text(
                  "Kategori: $namaJenisTampil",
                  style: const TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  tanggal,
                  style: const TextStyle(fontSize: 12, color: greyTextColor, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Bagian Samping Kanan: Menampilkan Harga Akumulasi Final secara Bold
          Text(
            totalHarga,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: primaryColor),
          ),
        ],
      ),
    );
  }
}