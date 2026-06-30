import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asriapp/config.dart';
import '../kurir/SetorSampahPage.dart';

const primaryColor = Color(0xFF1E521E);
const backgroundColor = Color(0xFFF9FBF9);

class ScanBarcodePage extends StatefulWidget {
  final int jadwalId;
  final int nasabahId; // ID Nasabah dari jadwal (jika ada)

  const ScanBarcodePage({
    super.key,
    this.jadwalId = 0,
    this.nasabahId = 0,
  });

  @override
  State<ScanBarcodePage> createState() => _ScanBarcodePageState();
}

class _ScanBarcodePageState extends State<ScanBarcodePage> {
  final MobileScannerController controller = MobileScannerController();
  bool isScanCompleted = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String kode) async {
    if (isScanCompleted) return;
    setState(() => isScanCompleted = true);

    try {
      // 1. Ambil ID Kurir yang sedang login dari SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int kurirId = 0;
      if (prefs.containsKey('user_id')) {
        final rawId = prefs.get('user_id');
        if (rawId is int) {
          kurirId = rawId;
        } else if (rawId is String) {
          kurirId = int.tryParse(rawId) ?? 0;
        }
      }

      // 2. Kirim kode string asli (misal: 'NSB001') langsung ke backend
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/kurir/scan-qr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nasabah_id': kode.trim(), // Mengirim string 'NSB001' langsung tanpa di-parse ke int
          'kurir_id': kurirId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final String mode = data['mode'];
          final int? idTransaksiInduk = data['id_transaksi'];
          final Map<String, dynamic> nasabah = data['nasabah'];

          // Matikan controller kamera sebelum berpindah halaman agar memori aman (mencegah BufferQueue abandoned)
          await controller.stop();

          if (mounted) {
            final result = await Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SetorSampahPage(
                  nasabahId: nasabah['id'], // ID asli integer dari database (29)
                  namaNasabah: nasabah['nama'],
                  alamat: nasabah['alamat'],
                  barcode: kode,
                  jadwalId: widget.jadwalId != 0 ? widget.jadwalId : 0,
                ),
              ),
            );
            if (result == true) Navigator.pop(context, true);
          }
        } else {
          _showError(data['message'] ?? "Gagal memvalidasi status nasabah.");
        }
      } else {
        _showError("Nasabah atau data jadwal tidak ditemukan di server!");
      }
    } catch (e) {
      debugPrint("ERROR SCAN QR: $e");
      _showError("Gagal memproses rute penjemputan.");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    setState(() => isScanCompleted = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("Scan QR Nasabah", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            _handleScan(barcodes.first.rawValue!);
          }
        },
      ),
    );
  }
}