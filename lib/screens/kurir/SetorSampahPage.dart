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

  const SetorSampahPage({
    super.key,
    required this.nasabahId,
    required this.namaNasabah,
    required this.alamat,
    required this.barcode,
  });

  @override
  State<SetorSampahPage> createState() =>
      _SetorSampahPageState();
}

class _SetorSampahPageState
    extends State<SetorSampahPage> {

  final TextEditingController jenisController =
  TextEditingController();

  final TextEditingController beratController =
  TextEditingController();

  final TextEditingController totalController =
  TextEditingController();

  File? imageFile;

  final picker = ImagePicker();

  List jenisSampahList = [];

  Map<String, dynamic>? selectedJenisSampah;

  int hargaPerKg = 0;

  // =========================
  // HITUNG TOTAL
  // =========================
  void hitungTotalPendapatan() {

    double berat =
        double.tryParse(
          beratController.text,
        ) ?? 0;

    double total =
        berat * hargaPerKg;

    totalController.text =
        total.toStringAsFixed(0);

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
          // Pastikan dicasting menjadi List<Map<String, dynamic>>
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

        imageFile = File(
          pickedFile.path,
        );

      });

    }

  }

  // =========================
  // SIMPAN DATA
  // =========================
  Future<void> simpanSetorSampah() async {

    String jenis = jenisController.text;

    String berat = beratController.text;

    String total = totalController.text;

    if (jenis.isEmpty ||
        berat.isEmpty ||
        total.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text(
            "Semua field wajib diisi",
          ),

        ),

      );

      return;

    }

    print(
      "Nasabah ID : ${widget.nasabahId}",
    );

    print(
      "Barcode : ${widget.barcode}",
    );

    print(
      "Jenis : $jenis",
    );

    print(
      "Berat : $berat",
    );

    print(
      "Total Pendapatan : $total",
    );

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(

        content: Text(
          "Data setor sampah berhasil disimpan",
        ),

      ),

    );

    Navigator.pop(context);

  }

  @override
  void initState() {
    super.initState();

    getJenisSampah();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(
        0xffF5F7FA,
      ),

      appBar: AppBar(

        elevation: 0,

        backgroundColor: Colors.green,

        title: const Text(

          "Setor Sampah",

          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),

        ),

      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // ======================
            // BARCODE NASABAH
            // ======================
            Container(

              width: double.infinity,

              padding:
              const EdgeInsets.all(20),

              decoration: BoxDecoration(

                color: Colors.green,

                borderRadius:
                BorderRadius.circular(18),

              ),

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  const Text(

                    "Kode Nasabah",

                    style: TextStyle(
                      color: Colors.white70,
                    ),

                  ),

                  const SizedBox(height: 8),

                  Text(

                    widget.barcode,

                    style: const TextStyle(

                      color: Colors.white,

                      fontSize: 24,

                      fontWeight:
                      FontWeight.bold,

                    ),

                  ),

                ],

              ),

            ),

            const SizedBox(height: 20),

            // ======================
            // DATA NASABAH
            // ======================
            Container(

              width: double.infinity,

              padding:
              const EdgeInsets.all(20),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius:
                BorderRadius.circular(18),

              ),

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  const Text(

                    "Data Nasabah",

                    style: TextStyle(

                      fontSize: 16,

                      fontWeight:
                      FontWeight.bold,

                    ),

                  ),

                  const SizedBox(height: 16),

                  Row(

                    children: [

                      const Icon(
                        Icons.person,
                        color: Colors.green,
                      ),

                      const SizedBox(width: 12),

                      Expanded(

                        child: Text(
                          widget.namaNasabah,
                        ),

                      ),

                    ],

                  ),

                  const SizedBox(height: 14),

                  Row(

                    children: [

                      const Icon(
                        Icons.location_on,
                        color: Colors.green,
                      ),

                      const SizedBox(width: 12),

                      Expanded(

                        child: Text(
                          widget.alamat,
                        ),

                      ),

                    ],

                  ),

                ],

              ),

            ),

            const SizedBox(height: 25),

            // ======================
            // JENIS SAMPAH
            // ======================
            DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedJenisSampah,
              decoration: InputDecoration(
                labelText: "Jenis Sampah",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
              // Map list yang sudah dicasting dengan benar
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

                  // Ambil nilai harga_per_kg dari API
                  final hargaRaw = value['harga_per_kg'];

                  if (hargaRaw is int) {
                    hargaPerKg = hargaRaw;
                  } else if (hargaRaw is double) {
                    hargaPerKg = hargaRaw.toInt();
                  } else if (hargaRaw is String) {
                    // Skenario API kamu: "2000.00" di-parse ke double dulu baru ke int
                    hargaPerKg = double.tryParse(hargaRaw)?.toInt() ?? 0;
                  } else {
                    hargaPerKg = 0;
                  }

                  // Pindahkan fungsi ini ke DALAM setState agar kalkulasinya
                  // langsung menggunakan nilai hargaPerKg yang paling baru updated.
                  hitungTotalPendapatan();
                });
              },
            ),

            const SizedBox(height: 15),

            // ======================
            // HARGA PER KG
            // ======================
            Container(

              width: double.infinity,

              padding:
              const EdgeInsets.all(16),

              decoration: BoxDecoration(

                color:
                Colors.green.shade50,

                borderRadius:
                BorderRadius.circular(14),

              ),

              child: Row(

                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

                children: [

                  const Text(

                    "Harga / Kg",

                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),

                  ),

                  Text(

                    "Rp $hargaPerKg",

                    style: const TextStyle(

                      fontWeight:
                      FontWeight.bold,

                      color: Colors.green,

                      fontSize: 16,

                    ),

                  ),

                ],

              ),

            ),

            const SizedBox(height: 20),

// ======================
// BERAT SAMPAH
// ======================
            TextField(

              controller: beratController,

              keyboardType: TextInputType.number,

              onChanged: (value) {

                hitungTotalPendapatan();

              },

              decoration: InputDecoration(

                labelText: "Berat Sampah (Kg)",

                hintText: "Contoh: 5",

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(

                  borderRadius:
                  BorderRadius.circular(14),

                  borderSide:
                  BorderSide.none,

                ),

              ),

            ),

            const SizedBox(height: 20),

// ======================
// TOTAL PENDAPATAN
// ======================
            TextField(

              controller: totalController,

              readOnly: true,

              decoration: InputDecoration(

                labelText: "Total Pendapatan",

                prefixText: "Rp ",

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(

                  borderRadius:
                  BorderRadius.circular(14),

                  borderSide:
                  BorderSide.none,

                ),

              ),

            ),

            const SizedBox(height: 25),

            // ======================
            // FOTO SAMPAH
            // ======================
            const Text(

              "Foto Sampah",

              style: TextStyle(

                fontSize: 16,

                fontWeight:
                FontWeight.bold,

              ),

            ),

            const SizedBox(height: 12),

            GestureDetector(

              onTap: pickImage,

              child: Container(

                width: double.infinity,

                height: 220,

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius:
                  BorderRadius.circular(18),

                ),

                child: imageFile == null

                    ? const Column(

                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  children: [

                    Icon(

                      Icons.camera_alt,

                      size: 60,

                      color: Colors.grey,

                    ),

                    SizedBox(height: 12),

                    Text(
                      "Ambil Foto Sampah",
                    ),

                  ],

                )

                    : ClipRRect(

                  borderRadius:
                  BorderRadius.circular(18),

                  child: Image.file(

                    imageFile!,

                    fit: BoxFit.cover,

                  ),

                ),

              ),

            ),

            const SizedBox(height: 30),

            // ======================
            // BUTTON SIMPAN
            // ======================
            SizedBox(

              width: double.infinity,

              height: 55,

              child: ElevatedButton(

                style:
                ElevatedButton.styleFrom(

                  elevation: 0,

                  backgroundColor:
                  Colors.green,

                  shape:
                  RoundedRectangleBorder(

                    borderRadius:
                    BorderRadius.circular(14),

                  ),

                ),

                onPressed:
                simpanSetorSampah,

                child: const Text(

                  "Simpan Setor Sampah",

                  style: TextStyle(

                    color: Colors.white,

                    fontSize: 16,

                    fontWeight:
                    FontWeight.bold,

                  ),

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }

}