import 'dart:convert';
import 'dart:io';

import 'package:asriapp/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class SetorSampahPage extends StatefulWidget {
  final int nasabahId;
  final String namaNasabah;
  final String alamat;
  final String barcode;
  // ==========================================
  // BERHASIL DITAMBAHKAN: Deklarasi Jadwal ID
  // ==========================================
  final int jadwalId;

  const SetorSampahPage({
    super.key,
    required this.nasabahId,
    required this.namaNasabah,
    required this.alamat,
    required this.barcode,
    required this.jadwalId, // Wajib diisi saat pindah halaman
  });

  @override
  State<SetorSampahPage> createState() => _SetorSampahPageState();
}

class _SetorSampahPageState extends State<SetorSampahPage> {
  final TextEditingController jenisController = TextEditingController();
  final TextEditingController beratController = TextEditingController();
  final TextEditingController totalController = TextEditingController();

  File? imageFile;
  final picker = ImagePicker();
  List jenisSampahList = [];
  Map<String, dynamic>? selectedJenisSampah;
  int hargaPerKg = 0;

  // =========================
  // HITUNG TOTAL
  // =========================
  void hitungTotalPendapatan() {
    double berat = double.tryParse(beratController.text) ?? 0;
    double total = berat * hargaPerKg;
    totalController.text = total.toStringAsFixed(0);
  }

  // =========================
  // GET JENIS SAMPAH
  // =========================
  Future<void> getJenisSampah() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/jenis-sampah'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Jenis Sampah Response: $data');

        setState(() {
          jenisSampahList = data.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      }
    } catch (e) {
      print(e);
    }
  }

  // =========================
  // PICK IMAGE
  // =========================
  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  // ==========================================
  // SIMPAN DATA SETOR (UPLOAD TEKS + FOTO KE DB)
  // ==========================================
  Future<void> simpanSetorSampah() async {
    String jenis = jenisController.text;
    String berat = beratController.text;
    String total = totalController.text;

    if (jenis.isEmpty || berat.isEmpty || total.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua field wajib diisi")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );

    try {
      var uri = Uri.parse('${AppConfig.baseUrl}/setor-sampah');
      var request = http.MultipartRequest('POST', uri);

      // Memasukkan field ke request multipart
      request.fields['user_id'] = widget.nasabahId.toString();
      // ==========================================
      // KINI AMAN: Memakai widget.jadwalId tanpa error
      // ==========================================
      request.fields['jadwal_id'] = widget.jadwalId.toString();
      request.fields['kurir_id'] = "14"; // Silakan ganti dengan ID dinamis dari Prefs jika sudah ada
      request.fields['jenis_sampah_id'] = selectedJenisSampah?['id'].toString() ?? '';
      request.fields['berat'] = berat;
      request.fields['harga_per_kg'] = hargaPerKg.toString();
      request.fields['total'] = total;
      request.fields['catatan'] = "Disetor lewat aplikasi kurir";

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'foto_sampah',
            imageFile!.path,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (mounted) Navigator.pop(context); // Tutup loading dialog

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Data setor sampah berhasil masuk ke database!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Pulang ke Scanner membawa sinyal sukses
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal: ${errorData['message'] ?? response.reasonPhrase}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kesalahan koneksi: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getJenisSampah();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green,
        title: const Text(
          "Setor Sampah",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BARCODE KODE NASABAH
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Kode Nasabah", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(
                    widget.barcode,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // KARTU DETAIL DATA NASABAH
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Data Nasabah", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(child: Text(widget.namaNasabah)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(child: Text(widget.alamat)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // SELEKSI DROPDOWN JENIS SAMPAH
            DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedJenisSampah,
              decoration: InputDecoration(
                labelText: "Jenis Sampah",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
              items: jenisSampahList.map<DropdownMenuItem<Map<String, dynamic>>>((item) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: item,
                  child: Text(item['nama'] ?? '-'),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedJenisSampah = value;
                  jenisController.text = value['nama'] ?? '';

                  final hargaRaw = value['harga_per_kg'];
                  if (hargaRaw is int) {
                    hargaPerKg = hargaRaw;
                  } else if (hargaRaw is double) {
                    hargaPerKg = hargaRaw.toInt();
                  } else if (hargaRaw is String) {
                    hargaPerKg = double.tryParse(hargaRaw)?.toInt() ?? 0;
                  } else {
                    hargaPerKg = 0;
                  }
                  hitungTotalPendapatan();
                });
              },
            ),
            const SizedBox(height: 15),

            // HARGA PER KG INFO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Harga / Kg", style: TextStyle(fontWeight: FontWeight.w600)),
                  Text("Rp $hargaPerKg", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // FORM INPUT BERAT
            TextField(
              controller: beratController,
              keyboardType: TextInputType.number,
              onChanged: (value) => hitungTotalPendapatan(),
              decoration: InputDecoration(
                labelText: "Berat Sampah (Kg)",
                hintText: "Contoh: 5",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            // FORM READ-ONLY TOTAL PENDAPATAN
            TextField(
              controller: totalController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Total Pendapatan",
                prefixText: "Rp ",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 25),

            // CAPTURE MEDIA FOTO SAMPAH
            const Text("Foto Sampah", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: pickImage,
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: imageFile == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text("Ambil Foto Sampah"),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(imageFile!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: simpanSetorSampah,
                child: const Text(
                  "Simpan Setor Sampah",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}