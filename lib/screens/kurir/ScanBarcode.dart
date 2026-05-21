import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../kurir/SetorSampahPage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:asriapp/config.dart';

class ScanBarcodePage extends StatefulWidget {
  final int jadwalId;

  const ScanBarcodePage({
    super.key,
    required this.jadwalId,
  });

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

  String namaNasabah = '-';
  String nomorHp = '-';
  String alamat = '-';
  int? nasabahId; // Menyimpan temporary ID untuk tombol manual di bawah
  String scannedBarcode = '';

  // ==========================================
  // PERBAIKAN: Tambahkan setState agar UI refresh saat scan ulang
  // ==========================================
  void closeScanner() {
    setState(() {
      isScanCompleted = false;
      namaNasabah = '-';
      nomorHp = '-';
      alamat = '-';
      nasabahId = null;
      scannedBarcode = '';
    });
  }

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
              // SCANNER FIELD
              // ======================
              Container(
                height: 350,
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
                            scannedBarcode = kode;
                          });

                          try {
                            final response = await http.get(
                              Uri.parse('${AppConfig.baseUrl}/nasabah/qrcode/$kode'),
                            );

                            if (response.statusCode == 200) {
                              final data = jsonDecode(response.body);

                              // Update UI peninjauan data di kartu bawah terlebih dahulu
                              setState(() {
                                nasabahId = data['id'];
                                namaNasabah = data['name'] ?? '-';
                                nomorHp = data['no_hp'] ?? '-'; // Sesuaikan key kolom HP dari backend API kamu
                                alamat = data['alamat'] ?? '-';
                              });

                              // Langsung arahkan otomatis ke Halaman Setor
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SetorSampahPage(
                                    nasabahId: data['id'],
                                    namaNasabah: data['name'],
                                    alamat: data['alamat'],
                                    barcode: kode,
                                    // SINKRON: Teruskan variabel jadwalId milik widget utama ke SetorSampahPage
                                    jadwalId: widget.jadwalId,
                                  ),
                                ),
                              );

                              // Jika setelah setor berhasil ditekan tombol simpan, lempar sinyal sukses ke halaman sebelumnya (Dashboard/Jadwal)
                              if (result == true && mounted) {
                                Navigator.pop(context, true);
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nasabah tidak ditemukan')),
                              );
                              setState(() {
                                isScanCompleted = false;
                              });
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
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
              const SizedBox(height: 24),

              // ======================
              // HASIL PENINJAUAN DATA SCAN
              // ======================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.green,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Ditambah AxisAlignment
                            children: [
                              Text(
                                namaNasabah,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Data Nasabah', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    infoTile(
                      icon: Icons.phone,
                      title: 'Nomor HP',
                      value: nomorHp,
                    ),
                    const SizedBox(height: 14),
                    infoTile(
                      icon: Icons.location_on,
                      title: 'Alamat',
                      value: alamat,
                    ),
                    const SizedBox(height: 28),

                    // BUTTON LANJUT MANUAL (Jika User tidak sengaja keluar kembali ke halaman ini)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        onPressed: nasabahId == null
                            ? null
                            : () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SetorSampahPage(
                                nasabahId: nasabahId!,
                                namaNasabah: namaNasabah,
                                alamat: alamat,
                                barcode: scannedBarcode,
                                jadwalId: widget.jadwalId,
                              ),
                            ),
                          );
                          if (result == true && mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                        icon: const Icon(Icons.arrow_forward, color: Colors.white),
                        label: const Text(
                          'Lanjut Setor Sampah',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: closeScanner,
                      child: const Text(
                        'Scan Ulang',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF8F9FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}