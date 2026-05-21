import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../kurir/SetorSampahPage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:asriapp/config.dart';

class ScanBarcodePage extends StatefulWidget {
  const ScanBarcodePage({super.key});

  @override
  State<ScanBarcodePage> createState() => _ScanBarcodePageState();
}

class _ScanBarcodePageState extends State<ScanBarcodePage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool isScanCompleted = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green,
        centerTitle: true,
        title: const Text(
          'Scan Barcode Nasabah',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ======================
              // HEADER CARD
              // ======================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff198754),
                      Color(0xff157347),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scanner Kurir',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Arahkan kamera ke barcode nasabah untuk melakukan setor sampah.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 45,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ======================
              // SCANNER AREA (FULL WIDTH)
              // ======================
              Container(
                height: 450, // Dipertinggi sedikit agar area pandang kamera lebih luas
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: MobileScanner(
                    controller: controller,
                    onDetect: (capture) async {
                      if (isScanCompleted) return;

                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final String? kode = barcode.rawValue;

                        if (kode != null) {
                          setState(() {
                            isScanCompleted = true;
                          });

                          try {
                            // Munculkan loading indicator kecil biar kurir tahu sistem sedang memproses
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(color: Colors.green),
                              ),
                            );

                            final response = await http.get(
                              Uri.parse('${AppConfig.baseUrl}/nasabah/qrcode/$kode'),
                            );

                            // Tutup dialog loading
                            if (mounted) Navigator.pop(context);

                            if (response.statusCode == 200) {
                              final data = jsonDecode(response.body);

                              if (mounted) {
                                // Tunggu sampai halaman SetorSampah ditutup
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SetorSampahPage(
                                      nasabahId: data['id'],
                                      namaNasabah: data['name'],
                                      alamat: data['alamat'],
                                      barcode: kode,
                                    ),
                                  ),
                                );

                                // SETELAH KEMBALI (BACK) DARI SETOR SAMPAH, SCANNER DIAKTIFKAN LAGI
                                setState(() {
                                  isScanCompleted = false;
                                });
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nasabah tidak ditemukan'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              setState(() {
                                isScanCompleted = false;
                              });
                            }
                          } catch (e) {
                            // Tutup dialog loading jika terjadi error catch
                            if (mounted) Navigator.pop(context);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            setState(() {
                              isScanCompleted = false;
                            });
                          }
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}