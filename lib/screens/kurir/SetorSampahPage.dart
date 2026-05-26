import 'dart:convert';
import 'dart:io';

import 'package:asriapp/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// 🎨 PALET WARNA UTAMA (Tema Konsisten Senior-Friendly Mai)
const primaryColor = Color(0xFF1E521E);
const secondaryColor = Color(0xFF4CAF50);
const softGreenColor = Color(0xFFE8F5E9);
const backgroundColor = Color(0xFFF9FBF9);
const darkTextColor = Color(0xFF0D240D);
const greyTextColor = Color(0xFF555555);

class SetorSampahPage extends StatefulWidget {
  final int nasabahId;
  final String namaNasabah;
  final String alamat;
  final String barcode;
  final int jadwalId;

  const SetorSampahPage({
    super.key,
    required this.nasabahId,
    required this.namaNasabah,
    required this.alamat,
    required this.barcode,
    required this.jadwalId,
  });

  @override
  State<SetorSampahPage> createState() => _SetorSampahPageState();
}

class _SetorSampahPageState extends State<SetorSampahPage> {
  final TextEditingController beratController = TextEditingController();

  File? imageFile;
  final picker = ImagePicker();
  List jenisSampahList = [];
  Map<String, dynamic>? selectedJenisSampah;
  int hargaPerKg = 0;
  bool isCapturingIot = false;

  // 🛠️ STATE BARU: Keranjang Belanja Multi-Item Sampah
  List<Map<String, dynamic>> keranjangSampah = [];
  int grandTotalSemua = 0;

  // ========================================================
  // AMBIL DATA BERAT DARI TIMBANGAN IOT LARAVEL
  // ========================================================
  Future<void> fetchBeratFromIot() async {
    setState(() {
      isCapturingIot = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/berat-timbangan-iot'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double beratIot = double.parse(data['berat_iot'].toString());

        setState(() {
          beratController.text = beratIot.toString();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Berat berhasil dimuat dari IoT: $beratIot Kg"),
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        throw Exception("Gagal merespon alat timbangan");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Gagal terhubung ke Timbangan IoT: $e"),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isCapturingIot = false;
        });
      }
    }
  }

  // ========================================================
  // FUNGSI: TAMBAH ITEM KE KERANJANG SEMENTARA
  // ========================================================
  void tambahKeKeranjang() {
    double berat = double.tryParse(beratController.text) ?? 0;

    if (selectedJenisSampah == null) {
      tampilkanPesan("❌ Pilih kategori jenis sampah terlebih dahulu!", Colors.red.shade800);
      return;
    }
    if (berat <= 0) {
      tampilkanPesan("❌ Berat sampah harus lebih dari 0 Kg!", Colors.red.shade800);
      return;
    }

    int totalItem = (berat * hargaPerKg).round();

    setState(() {
      // Masukkan ke list tampungan
      keranjangSampah.add({
        'jenis_sampah_id': selectedJenisSampah!['id'],
        'nama_sampah': selectedJenisSampah!['nama'],
        'berat': berat,
        'harga_per_kg': hargaPerKg,
        'total_item': totalItem,
      });

      // Hitung ulang grand total keseluruhan uang
      hitungGrandTotal();

      // Reset input berat dan pilihan dropdown agar bisa input item selanjutnya
      beratController.clear();
      selectedJenisSampah = null;
      hargaPerKg = 0;
    });

    tampilkanPesan("📥 Berhasil ditambahkan ke daftar!", primaryColor);
  }

  // ========================================================
  // FUNGSI: HAPUS ITEM DARI KERANJANG
  // ========================================================
  void hapusItemKeranjang(int index) {
    setState(() {
      keranjangSampah.removeAt(index);
      hitungGrandTotal();
    });
  }

  void hitungGrandTotal() {
    grandTotalSemua = keranjangSampah.fold(0, (sum, item) => sum + (item['total_item'] as int));
  }

  // ========================================================
  // AMBIL DAFTAR JENIS SAMPAH DARI BACKEND
  // ========================================================
  Future<void> getJenisSampah() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/jenis-sampah'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          jenisSampahList = data.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      }
    } catch (e) {
      print(e);
    }
  }

  // ========================================================
  // AMBIL FOTO SAMPAH MENGGUNAKAN KAMERA HP
  // ========================================================
  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  // ========================================================
  // SIMPAN DATA SETOR MASAL (KIRIM ARRAY JSON KONTROLLER BARU)
  // ========================================================
  Future<void> simpanSetorSampah() async {
    if (keranjangSampah.isEmpty) {
      tampilkanPesan("❌ Keranjang masih kosong! Tambahkan minimal 1 jenis sampah.", Colors.red.shade800);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: primaryColor, strokeWidth: 4),
      ),
    );

    try {
      var uri = Uri.parse('${AppConfig.baseUrl}/setor-sampah');
      var request = http.MultipartRequest('POST', uri);

      // Sesuai dengan parameter request di SetorSampahController Laravel multi-item yang kita buat kemarin
      request.fields['user_id'] = widget.nasabahId.toString();
      request.fields['jadwal_id'] = widget.jadwalId.toString();
      request.fields['kurir_id'] = "14";
      request.fields['grand_total'] = grandTotalSemua.toString();
      request.fields['catatan'] = "Disetor massal lewat aplikasi kurir";

      // Enkode list keranjang menjadi format String JSON Array murni
      request.fields['sampah_list'] = jsonEncode(keranjangSampah);

      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('foto_sampah', imageFile!.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (mounted) Navigator.pop(context); // Tutup loading

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          tampilkanPesan("✅ Semua jenis sampah berhasil disimpan ke database!", primaryColor);
          Navigator.pop(context, true); // Kembali ke riwayat/halaman utama kurir
        }
      } else {
        final errorData = jsonDecode(response.body);
        tampilkanPesan("Gagal: ${errorData['message'] ?? response.reasonPhrase}", Colors.red);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      tampilkanPesan("Kesalahan koneksi: $e", Colors.red);
    }
  }

  void tampilkanPesan(String pesan, Color warnaBg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: warnaBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    getJenisSampah();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Setor Multi Sampah",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, Color(0xFF2E6B2E)],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BARCODE & INFORMASI NASABAH (Dibuat ringkas biar space muat)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.namaNasabah, style: const TextStyle(fontWeight: FontWeight.w900, color: darkTextColor, fontSize: 16)),
                      Text(widget.barcode, style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14)),
                    ],
                  ),
                  const Divider(height: 16),
                  Text(widget.alamat, style: const TextStyle(color: greyTextColor, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // SECTION 1: FORM INPUT ITEM SAMPAH
            const Text("1. Timbang & Pilih Item", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: darkTextColor)),
            const SizedBox(height: 10),

            DropdownButtonFormField<Map<String, dynamic>>(
              value: selectedJenisSampah,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_circle_rounded, color: primaryColor),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(20),
              style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.w800, fontSize: 15),
              decoration: InputDecoration(
                labelText: "Kategori Jenis Sampah",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.recycling_rounded, color: primaryColor),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryColor, width: 2)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
              ),
              items: jenisSampahList.map<DropdownMenuItem<Map<String, dynamic>>>((item) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: item,
                  child: Row(
                    children: [
                      const Icon(Icons.eco_rounded, color: secondaryColor, size: 18),
                      const SizedBox(width: 10),
                      Text(item['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedJenisSampah = value;
                  final hargaRaw = value['harga_per_kg'];
                  hargaPerKg = (hargaRaw is num) ? hargaRaw.toInt() : (double.tryParse(hargaRaw.toString())?.toInt() ?? 0);
                });
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: beratController,
                    style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.w900),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Berat (Kg)",
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.scale_rounded, color: primaryColor),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryColor, width: 2)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isCapturingIot ? null : fetchBeratFromIot,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: isCapturingIot
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.wifi_rounded, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),

                // ➕ TOMBOL TAMBAH KE DAFTAR KERANJANG SEMENTARA
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: tambahKeKeranjang,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 18),
                    label: const Text("TAMBAH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // SECTION 2: DAFTAR KERANJANG BELANJA SAMPAH
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("2. List Keranjang Sampah", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: darkTextColor)),
                Text("${keranjangSampah.length} Item", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
            const SizedBox(height: 10),

            // RENDER KARTU DAFTAR ITEM YANG MAU DISETOR
            keranjangSampah.isEmpty
                ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid)),
              child: const Center(child: Text("Belum ada item di keranjang", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13))),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: keranjangSampah.length,
              itemBuilder: (context, index) {
                final item = keranjangSampah[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: softGreenColor, child: Icon(Icons.eco_rounded, color: primaryColor)),
                    title: Text(item['nama_sampah'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    subtitle: Text("${item['berat']} Kg x Rp ${numberFormat(item['harga_per_kg'])}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Rp ${numberFormat(item['total_item'])}", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          onPressed: () => hapusItemKeranjang(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // GRAND TOTAL SALDO YANG MASUK
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: softGreenColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: primaryColor.withOpacity(0.2))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("TOTAL SALDO MASUK", style: TextStyle(fontWeight: FontWeight.w900, color: darkTextColor, fontSize: 13)),
                  Text("Rp ${numberFormat(grandTotalSemua)}", style: const TextStyle(fontWeight: FontWeight.w900, color: primaryColor, fontSize: 20)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 3: CAPTURE FOTO BUKTI MASAL
            const Text("3. Foto Bukti Penimbangan", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: darkTextColor)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: pickImage,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200, width: 1.5)),
                child: imageFile == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded, size: 44, color: primaryColor),
                    SizedBox(height: 8),
                    Text("Ambil Foto Timbangan Semua Sampah", style: TextStyle(color: greyTextColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                )
                    : ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(imageFile!, fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 32),

            // SUBMIT FINAL ACTION BUTTON
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: simpanSetorSampah,
                child: const Text(
                  "SIMPAN SETOR SAMPAH",
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String numberFormat(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}