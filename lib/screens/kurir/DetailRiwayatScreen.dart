import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart'; // Import library screenshot
import 'package:gal/gal.dart'; // Import library penyimpan galeri

// Palet warna kontras tinggi Bank Sampah Mai
const primaryColor = Color(0xFF1E521E);
const backgroundColor = Color(0xFFF9FBF9);
const darkTextColor = Color(0xFF0D240D);
const greyTextColor = Color(0xFF555555);

class DetailRiwayatScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const DetailRiwayatScreen({super.key, required this.data});

  @override
  State<DetailRiwayatScreen> createState() => _DetailRiwayatScreenState();
}

class _DetailRiwayatScreenState extends State<DetailRiwayatScreen> {
  // Controller untuk menangkap gambar widget struk
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isDownloading = false;

  // Fungsi Sakti Mendownload Struk ke Galeri
  Future<void> _downloadStruk(String noTrx) async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // 1. Cek atau minta izin penyimpanan perangkat sebelum mengeksekusi
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      // 2. Tangkap gambar dari widget kertas struk dengan pixelRatio lebih tinggi agar jernih
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 50),
      );

      if (imageBytes != null) {
        // 3. Simpan bytes gambar langsung ke galeri HP
        await Gal.putImageBytes(imageBytes);

        // 4. Tampilkan notifikasi sukses kepada pengguna
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
    String namaJenis = widget.data['jenis_sampah']?['nama'] ?? 'Sampah Umum';
    String tanggal = widget.data['created_at_formatted'] ?? widget.data['created_at'] ?? '-';
    String beratSampah = "${widget.data['berat']?.toString() ?? '0'} Kg";
    String hargaPerKg = "Rp ${widget.data['harga_per_kg']?.toString() ?? '0'}";
    String totalHarga = "Rp ${widget.data['total']?.toString() ?? '0'}";
    String catatan = widget.data['catatan'] ?? 'Disetor lewat aplikasi kurir';
    String nomorTransaksi = "TRX-${widget.data['id'] ?? '000'}";

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

            // ================= KERTAS STRUK DIGITAL (DI-SCREENSHOT) =================
            Screenshot(
              controller: _screenshotController,
              child: Container(
                width: double.infinity,
                // Menggunakan dekorasi warna solid agar saat dicapture latar belakangnya tidak transparan
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
                              totalHarga,
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

                          _rowStruk(label: "Nama Nasabah", value: namaNasabah),
                          _rowStruk(label: "Waktu Setor", value: tanggal),
                          _rowStruk(label: "Kategori Sampah", value: namaJenis),
                          _rowStruk(label: "Berat Bersih", value: beratSampah, valueColor: Colors.orange.shade900),
                          _rowStruk(label: "Harga per Kg", value: hargaPerKg),
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

                    // 🛠️ FIX LAYOUT ERROR: Mengamankan gerigi bawah agar tidak mengacaukan kalkulasi render screenshot
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

            // 🔥 TOMBOL DOWNLOAD STRUK KE GALERI HP
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
      padding: const EdgeInsets.only(bottom: 16),
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
}