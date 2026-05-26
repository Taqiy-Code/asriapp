import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart'; // Import library screenshot
import 'package:gal/gal.dart'; // Import library penyimpan galeri
import 'package:intl/intl.dart';

// Palet warna kontras tinggi Bank Sampah Basayan Bestari
const primaryColor = Color(0xFF1E521E);
const backgroundColor = Color(0xFFF9FBF9);
const softGreenColor = Color(0xFFE8F5E9);
const darkTextColor = Color(0xFF0D240D);
const greyTextColor = Color(0xFF555555);

class DetailRiwayatScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const DetailRiwayatScreen({super.key, required this.data});

  @override
  State<DetailRiwayatScreen> createState() => _DetailRiwayatScreenState();
}

class _DetailRiwayatScreenState extends State<DetailRiwayatScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isDownloading = false;

  // Fungsi Sakti Mendownload Struk ke Galeri
  Future<void> _downloadStruk(String noTrx) async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 50),
      );

      if (imageBytes != null) {
        await Gal.putImageBytes(imageBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Struk Berhasil Disimpan ke Galeri HP!"),
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception("Gagal memproses gambar struk.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Gagal mendownload struk: $e"),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String namaNasabah = widget.data['nasabah']?['name'] ?? 'Nasabah ASRI';
    String rawDate = widget.data['created_at'] ?? '';
    String tanggal = '-';

    if (rawDate.isNotEmpty) {
      try {
        DateTime parsedDate = DateTime.parse(rawDate);
        tanggal = DateFormat('dd MMMM yyyy, HH:mm').format(parsedDate) + " WIB";
      } catch (e) {
        tanggal = widget.data['created_at_formatted'] ?? rawDate;
      }
    }

    // Format Rupiah Akumulasi Grand Total
    String grandTotal = "Rp " + widget.data['total'].toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.'
    );

    String catatan = widget.data['catatan'] ?? 'Disetor lewat aplikasi kurir';
    String nomorTransaksi = "TRX-${widget.data['id'] ?? '000'}";

    // Ambil list detail item penimbangan multi-item
    List<dynamic> details = widget.data['details'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Bukti Setoran Sampah",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ================= KERTAS STRUK DIGITAL MULTI-ITEM (DI-SCREENSHOT) =================
            Screenshot(
              controller: _screenshotController,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bagian Atas Struk (Identitas Bank Sampah)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 54),
                            SizedBox(height: 10),
                            Text(
                              "TRANSAKSI BERHASIL",
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Bank Sampah Basayan Bestari",
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bagian Rincian Data
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              grandTotal,
                              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: -0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              nomorTransaksi,
                              style: const TextStyle(fontSize: 13, color: greyTextColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(thickness: 1.5, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 16),

                          // Metadata Transaksi Utama
                          _rowStruk(label: "Nama Nasabah", value: namaNasabah),
                          _rowStruk(label: "Waktu Setor", value: tanggal),

                          const SizedBox(height: 8),
                          const Divider(thickness: 1.5, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 14),

                          // 📦 BARU: SECTION DAFTAR RINCIAN ITEM SAMPAH MULTI-ITEM
                          const Text(
                            "RINCIAN ITEM SAMPAH",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 0.3),
                          ),
                          const SizedBox(height: 12),

                          details.isEmpty
                              ? _buildLegacyRowFallback(widget.data) // Jika data penimbangan lama single-item
                              : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: details.length,
                            itemBuilder: (context, index) {
                              final item = details[index];
                              String namaItem = item['jenis_sampah']?['nama'] ?? 'Jenis Sampah';
                              String berat = "${item['berat']?.toString() ?? '0'} Kg";

                              String hargaFormat = "Rp " + item['harga_per_kg'].toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.'
                              );

                              String subtotalFormat = "Rp " + item['subtotal'].toString().replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.'
                              );

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "• $namaItem",
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: darkTextColor),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "$berat x $hargaFormat",
                                          style: const TextStyle(fontSize: 12, color: greyTextColor, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      subtotalFormat,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: darkTextColor),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 12),
                          const Divider(thickness: 1.5, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 16),

                          const Text(
                            "Catatan Timbangan:",
                            style: TextStyle(fontSize: 13, color: greyTextColor, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              catatan,
                              style: const TextStyle(fontSize: 14, color: darkTextColor, fontWeight: FontWeight.w600, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Gerigi Bawah Struk
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                        child: Row(
                          children: List.generate(
                            20,
                                (index) => Expanded(
                              child: Container(
                                height: 10,
                                color: index % 2 == 0 ? Colors.white : const Color(0xFFEEEEEE),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // TOMBOL DOWNLOAD STRUK KE GALERI HP
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isDownloading ? null : () => _downloadStruk(nomorTransaksi),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryColor, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isDownloading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2))
                    : const Icon(Icons.download_rounded, color: primaryColor),
                label: Text(
                  _isDownloading ? "MENYIMPAN..." : "DOWNLOAD STRUK (PNG)",
                  style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tombol Kembali
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  "KEMBALI KE RIWAYAT",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _rowStruk({required String label, required String value, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: greyTextColor, fontWeight: FontWeight.w700)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 14, color: valueColor ?? darkTextColor, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // Fallback pengaman data single-item lama agar struk tidak jebol saat dibuka
  Widget _buildLegacyRowFallback(Map<String, dynamic> data) {
    String namaJenis = data['jenis_sampah']?['nama'] ?? 'Sampah Umum';
    String berat = "${data['berat']?.toString() ?? '0'} Kg";

    String hargaFormat = "Rp " + data['harga_per_kg'].toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.'
    );

    String subtotalFormat = "Rp " + data['total'].toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.'
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• $namaJenis", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: darkTextColor)),
              const SizedBox(height: 2),
              Text("$berat x $hargaFormat", style: const TextStyle(fontSize: 12, color: greyTextColor, fontWeight: FontWeight.w600)),
            ],
          ),
          Text(subtotalFormat, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: darkTextColor)),
        ],
      ),
    );
  }
}