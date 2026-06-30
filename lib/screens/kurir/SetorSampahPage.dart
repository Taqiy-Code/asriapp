import 'dart:convert';
import 'dart:io';

import 'package:asriapp/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/jenis_sampah.dart';
import '../services/setor_sampah_service.dart';
import '../services/jenis_sampah_service.dart';

class AppColors {
  static const primary = Color(0xFF1E521E);
  static const secondary = Color(0xFF4CAF50);
  static const softGreen = Color(0xFFE8F5E9);
  static const background = Color(0xFFF9FBF9);
  static const darkText = Color(0xFF0D240D);
  static const greyText = Color(0xFF555555);
}

class SetorSampahPage extends StatefulWidget {
  final int nasabahId;
  final String namaNasabah;
  final String alamat;
  final String barcode;
  final int jadwalId;
  final Map<String, dynamic> jadwalData;

  const SetorSampahPage({
    super.key,
    required this.nasabahId,
    required this.namaNasabah,
    required this.alamat,
    required this.barcode,
    this.jadwalId = 0,
    this.jadwalData = const {},
  });

  @override
  State<SetorSampahPage> createState() => _SetorSampahPageState();
}

class _ScanBarcodePageState {}

class _SetorSampahPageState extends State<SetorSampahPage> {
  final TextEditingController _beratController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  File? _imageFile;
  final _picker = ImagePicker();
  List<JenisSampah> _jenisSampahList = [];
  JenisSampah? _selectedJenisSampah;

  bool _isCapturingIot = false;
  bool _isAutoloadLoading = false;
  bool _isRequestDataFromNasabah = false;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _keranjangSampah = [];
  int _grandTotalSemua = 0;
  int _selectedIndexKeranjang = 0;

  // 🧠 Logika penentu: Apakah ini benar-benar Request dari Nasabah yang beratnya masih 0?
  bool get isRealRequestNasabah => _isRequestDataFromNasabah;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _getJenisSampah();

    // 🧠 Jika datang dari rute jadwal tugas kurir, deteksi isi datanya langsung
    if (widget.jadwalId != 0 && widget.jadwalData.isNotEmpty) {
      _evaluasiJadwalData();
    } else if (widget.jadwalId == 0) {
      await _cekDanAutoloadRequestNasabah();
    }
  }

  // 🧠 FUNGSI BARU: Mengevaluasi apakah data dari daftar tugas bermuara ke Request Nasabah (berat 0) atau Jadwal Rutin
  void _evaluasiJadwalData() {
    var beratAwal = widget.jadwalData['berat'] ?? widget.jadwalData['total_berat'];
    double beratDouble = double.tryParse(beratAwal.toString()) ?? 0.0;

    if (beratDouble == 0.0) {
      // 🚨 JALUR REQUEST NASABAH: Kunci jenis sampah ke keranjang otomatis
      setState(() {
        _isRequestDataFromNasabah = true;
        _keranjangSampah = [
          {
            'jenis_sampah_id': widget.jadwalData['jenis_sampah_id'] ?? 0,
            'nama_sampah': widget.jadwalData['jenis_sampah'] ?? widget.jadwalData['nama_jenis'] ?? 'Sampah Request',
            'berat': 0.0,
            'harga_per_kg': widget.jadwalData['harga_per_kg'] ?? widget.jadwalData['harga'] ?? 0,
            'total_item': 0,
          }
        ];
        _selectedIndexKeranjang = 0;
        _hitungGrandTotal();
      });
      _tampilkanPesan("📦 Terdeteksi: Request Sampah Nasabah!", AppColors.primary);
    } else {
      // 🚨 JALUR JADWAL RUTIN: Biarkan kosong agar kurir bisa input manual multi-sampah
      setState(() {
        _isRequestDataFromNasabah = false;
        _keranjangSampah = [];
      });
      _tampilkanPesan("🗓️ Terdeteksi: Jalur Jadwal Rutin Admin (Form Manual)", AppColors.primary);
    }
  }

  Future<void> _getJenisSampah() async {
    try {
      final data = await JenisSampahService.getData();
      if (mounted) {
        setState(() {
          _jenisSampahList = data;
        });
      }
    } catch (e) {
      debugPrint("Gagal ambil jenis sampah: $e");
    }
  }

  Future<void> _cekDanAutoloadRequestNasabah() async {
    setState(() => _isAutoloadLoading = true);

    try {
      final requestData = await SetorSampahService.getRequestDetail(widget.nasabahId);

      if (requestData != null && requestData['items'] != null && (requestData['items'] as List).isNotEmpty) {
        List<dynamic> itemsDariNasabah = requestData['items'];

        setState(() {
          _isRequestDataFromNasabah = true;
          _keranjangSampah = itemsDariNasabah.map((item) => {
            'jenis_sampah_id': item['jenis_sampah_id'],
            'nama_sampah': item['nama_sampah'] ?? item['nama_jenis'] ?? 'Sampah',
            'berat': 0.0,
            'harga_per_kg': item['harga_per_kg'] ?? 0,
            'total_item': 0,
          }).toList();

          _hitungGrandTotal();
        });
        _tampilkanPesan("✅ Data request berhasil dimuat!", AppColors.primary);
      }
    } catch (e) {
      debugPrint("Gagal memuat request detail: $e");
      _tampilkanPesan("Gagal memuat data request nasabah", Colors.red);
    } finally {
      if (mounted) setState(() => _isAutoloadLoading = false);
    }
  }

  Future<void> _fetchBeratFromIot() async {
    setState(() => _isCapturingIot = true);

    final berat = await SetorSampahService.fetchBeratIot();

    if (mounted) {
      setState(() => _isCapturingIot = false);
      if (berat != null) {
        _beratController.text = berat.toString();
      } else {
        _tampilkanPesan("Gagal terhubung ke Timbangan IoT", Colors.red.shade800);
      }
    }
  }

  void _tambahAtauUpdateBerat() {
    double berat = double.tryParse(_beratController.text) ?? 0;

    if (berat <= 0) {
      _tampilkanPesan("Berat sampah harus lebih dari 0 Kg!", Colors.red.shade800);
      return;
    }

    if (isRealRequestNasabah) {
      if (_selectedIndexKeranjang >= _keranjangSampah.length) {
        _tampilkanPesan("Pilih item di daftar keranjang dahulu!", Colors.red.shade800);
        return;
      }

      setState(() {
        var oldItem = _keranjangSampah[_selectedIndexKeranjang];
        int hargaBeli = (oldItem['harga_per_kg'] as num).toInt();
        int totalItemBaru = (berat * hargaBeli).round();

        _keranjangSampah[_selectedIndexKeranjang] = {
          ...oldItem,
          'berat': berat,
          'total_item': totalItemBaru,
        };

        _hitungGrandTotal();
        _beratController.clear();
      });
      _tampilkanPesan("Berhasil update berat item!", AppColors.primary);
    } else {
      if (_selectedJenisSampah == null) {
        _tampilkanPesan("Pilih kategori jenis sampah terlebih dahulu!", Colors.red.shade800);
        return;
      }

      int hargaBeli = _selectedJenisSampah!.harga.toInt();
      int totalItem = (berat * hargaBeli).round();

      setState(() {
        _keranjangSampah.add({
          'jenis_sampah_id': _selectedJenisSampah!.id,
          'nama_sampah': _selectedJenisSampah!.nama,
          'berat': berat,
          'harga_per_kg': hargaBeli,
          'total_item': totalItem,
        });

        _hitungGrandTotal();
        _beratController.clear();
        _selectedJenisSampah = null;
      });
      _tampilkanPesan("📥 Berhasil ditambahkan ke keranjang!", AppColors.primary);
    }
  }

  void _hapusItemKeranjang(int index) {
    if (isRealRequestNasabah) {
      _tampilkanPesan("Item request nasabah tidak boleh dihapus!", Colors.orange.shade900);
      return;
    }
    setState(() {
      _keranjangSampah.removeAt(index);
      _hitungGrandTotal();
    });
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _hitungGrandTotal() {
    _grandTotalSemua = _keranjangSampah.fold(0, (sum, item) => sum + (item['total_item'] as int));
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _simpanSetorSampah() async {
    _hideKeyboard();
    if (_keranjangSampah.isEmpty) {
      _tampilkanPesan("Keranjang masih kosong!", Colors.red.shade800);
      return;
    }

    if (isRealRequestNasabah) {
      bool adaYangBelumDitimbang = _keranjangSampah.any((item) => (item['berat'] ?? 0) <= 0);
      if (adaYangBelumDitimbang) {
        _tampilkanPesan("Harap isi berat untuk SEMUA item request nasabah!", Colors.red.shade800);
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final kurirId = prefs.getInt('user_id') ?? 0;

      // 🛠️ Pembedaan Eksekusi Fungsi Service Berdasarkan Mode Alur Data
      final http.Response response;

      if (isRealRequestNasabah) {
        // 🔄 Jalur 1: Menggunakan PATCH Request Nasabah
        // Ambil ID Setor gantung dari manifes request yang dimuat di awal
        final int setorSampahId = widget.jadwalData['id'] ?? 0;

        response = await SetorSampahService.submitSetoranRequestNasabah(
          setorSampahId: setorSampahId,
          userId: widget.nasabahId,
          kurirId: kurirId,
          grandTotal: _grandTotalSemua,
          catatan: "Setoran request nasabah diselesaikan oleh kurir",
          jadwalId: widget.jadwalId,
          sampahList: _keranjangSampah,
          imagePath: _imageFile?.path ?? "",
        );
      } else {
        // 🔄 Jalur 2: Menggunakan PATCH Jadwal Admin (Rutin / Manual)
        // Gunakan parameter id jadwal/setor yang dilempar oleh admin web
        final int targetId = widget.jadwalId;

        response = await SetorSampahService.submitSetoranJadwalAdmin(
          id: targetId,
          userId: widget.nasabahId,
          kurirId: kurirId,
          grandTotal: _grandTotalSemua,
          catatan: "Setoran manual kurir via jadwal admin",
          jadwalId: widget.jadwalId,
          sampahList: _keranjangSampah,
          imagePath: _imageFile?.path ?? "",
        );
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (response.statusCode == 200 || response.statusCode == 201) {
          _tampilkanPesan("✅ Setoran sukses disimpan!", AppColors.primary);
          Navigator.pop(context, true);
        } else {
          try {
            final errorData = jsonDecode(response.body);
            _tampilkanPesan("Gagal: ${errorData['message'] ?? response.reasonPhrase}", Colors.red);
          } catch (_) {
            _tampilkanPesan("Terjadi kendala sistem di hosting (Error ${response.statusCode})", Colors.red);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _tampilkanPesan("Kesalahan koneksi: $e", Colors.red);
      }
    }
  }

  void _tampilkanPesan(String pesan, Color warnaBg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: warnaBg,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isRealRequestNasabah ? "Proses Request Nasabah" : "Setor Multi Sampah",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isAutoloadLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoNasabah(),
            const SizedBox(height: 20),
            _buildInputSection(),
            const SizedBox(height: 24),
            _buildKeranjangHeader(),
            const SizedBox(height: 10),
            _buildKeranjangList(),
            const SizedBox(height: 20),
            _buildTotalSection(),
            const SizedBox(height: 20),
            _buildFotoSection(),
            const SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoNasabah() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.namaNasabah, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(widget.alamat, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("1. Input Berat Sampah", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (isRealRequestNasabah)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Text(
              "Mode Request Nasabah: Jenis sampah sudah terisi otomatis. Silakan pilih item di tabel bawah untuk mengisi beratnya.",
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          )
        else
          Column(
            children: [
              if (_jenisSampahList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.softGreen),
                )
              else
                DropdownButtonFormField<JenisSampah>(
                  value: _selectedJenisSampah,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Pilih Jenis Sampah",
                    hintText: _jenisSampahList.isEmpty ? "Data sampah tidak ditemukan" : "Pilih kategori",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _jenisSampahList.map((item) {
                    return DropdownMenuItem<JenisSampah>(
                      value: item,
                      child: Text(item.nama),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedJenisSampah = value),
                ),
              const SizedBox(height: 12),
            ],
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _beratController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Berat (Kg)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: "Ambil berat dari IoT",
              child: IconButton.filled(
                onPressed: _isCapturingIot ? null : _fetchBeratFromIot,
                icon: _isCapturingIot
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.monitor_weight_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _tambahAtauUpdateBerat,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              child: Text(isRealRequestNasabah ? "UPDATE" : "TAMBAH", style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeranjangHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("2. List Keranjang", style: TextStyle(fontWeight: FontWeight.bold)),
        Text("${_keranjangSampah.length} Jenis", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildKeranjangList() {
    if (_keranjangSampah.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Keranjang kosong")));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _keranjangSampah.length,
      itemBuilder: (context, index) {
        final item = _keranjangSampah[index];
        final bool isSelected = isRealRequestNasabah && _selectedIndexKeranjang == index;

        return Card(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: isSelected ? 2 : 1),
          ),
          child: ListTile(
            onTap: !isRealRequestNasabah ? null : () {
              setState(() {
                _selectedIndexKeranjang = index;
                _beratController.text = item['berat'] > 0 ? item['berat'].toString() : "";
              });
            },
            title: Text(item['nama_sampah'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${item['berat']} Kg x ${_currencyFormat.format(item['harga_per_kg'])}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_currencyFormat.format(item['total_item']), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                if (!isRealRequestNasabah)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _hapusItemKeranjang(index),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppColors.softGreen, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("TOTAL SALDO", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(_currencyFormat.format(_grandTotalSemua), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildFotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("3. Foto Bukti (Opsional)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _imageFile == null
                ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _simpanSetorSampah,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSubmitting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("SIMPAN DATA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}