import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

const primaryColor = Color(0xFF1E521E);
const backgroundColor = Color(0xFFF9FBF9);
const darkTextColor = Color(0xFF0D240D);
const greyTextColor = Color(0xFF555555);

class SuccessWithdrawalPage extends StatefulWidget {
  final int nominal;
  final String transactionId;
  final String method;
  final String phone;

  const SuccessWithdrawalPage({
    super.key,
    required this.nominal,
    required this.transactionId,
    this.method = "DANA",
    this.phone = "",
  });

  @override
  State<SuccessWithdrawalPage> createState() => _SuccessWithdrawalPageState();
}

class _SuccessWithdrawalPageState extends State<SuccessWithdrawalPage> {
  final ScreenshotController _screenshotController = ScreenshotController();

  String _formatRupiah(int angka) {
    return "Rp " + NumberFormat.decimalPattern('id').format(angka);
  }

  bool _isSaving = false;

  Future<void> _downloadScreenshot() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      // 1. Cek dan minta izin akses galeri
      bool hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        hasAccess = await Gal.requestAccess();
      }

      if (!hasAccess) {
        if (mounted) {
          _showError("Izin galeri ditolak. Silakan berikan izin di pengaturan HP.");
        }
        return;
      }

      // 2. Ambil screenshot
      final image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = File('${directory.path}/struk_tarik_tunai_${DateTime.now().millisecondsSinceEpoch}.png');
        await imagePath.writeAsBytes(image);

        // 3. Simpan ke Galeri
        await Gal.putImage(imagePath.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Struk berhasil disimpan ke galeri!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error saving: $e");
      if (mounted) _showError("Gagal mengunduh struk: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    String waktuSekarang = DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now()) + " WIB";

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Screenshot(
                controller: _screenshotController,
                child: Container(
                  width: double.infinity,
                  color: primaryColor, // Pastikan background ikut terscreenshot
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // HEADER SUKSES
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 80),
                      const SizedBox(height: 16),
                      const Text(
                        "Penarikan Berhasil!",
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const Text(
                        "Dana Anda telah berhasil diproses",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 40),

                      // KARTU STRUK
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Text(
                                  "JUMLAH PENARIKAN",
                                  style: TextStyle(color: greyTextColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatRupiah(widget.nominal),
                                  style: const TextStyle(color: primaryColor, fontSize: 36, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 32),
                                
                                const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                                const SizedBox(height: 32),

                                _buildDetailRow("ID Transaksi", widget.transactionId),
                                _buildDetailRow("Waktu", waktuSekarang),
                                _buildDetailRow("Metode", widget.method),
                                _buildDetailRow("Nomor HP", widget.phone),
                                _buildDetailRow("Status", "BERHASIL", isStatus: true),

                                const SizedBox(height: 40),
                                
                                // EFEK GARIS PUTUS-PUTUS
                                Row(
                                  children: List.generate(
                                    30,
                                    (index) => Expanded(
                                      child: Container(
                                        height: 2,
                                        color: index % 2 == 0 ? Colors.grey.shade200 : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 32),
                                const Text(
                                  "Simpan struk ini sebagai bukti penarikan yang sah dari Bank Sampah Basayan Bestari.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: greyTextColor, fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // TOMBOL AKSI
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _downloadScreenshot,
                      icon: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.download_rounded, color: Colors.white),
                      label: Text(_isSaving ? "MENYIMPAN..." : "UNDUH STRUK", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryColor, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("KEMBALI KE BERANDA", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: greyTextColor, fontSize: 14, fontWeight: FontWeight.w600)),
          Text(
            value,
            style: TextStyle(
              color: isStatus ? Colors.green.shade800 : darkTextColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
