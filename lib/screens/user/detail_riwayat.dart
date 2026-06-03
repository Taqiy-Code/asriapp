import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const primaryColor = Color(0xFF1E521E);
const secondaryColor = Color(0xFF4CAF50);
const softGreenColor = Color(0xFFE8F5E9);
const backgroundColor = Color(0xFFF9FBF9);
const darkTextColor = Color(0xFF0D240D);
const greyTextColor = Color(0xFF555555);

class DetailRiwayatPage extends StatelessWidget {
  final dynamic data;

  const DetailRiwayatPage({
    super.key,
    required this.data,
  });

  String formatDuitRupiah(dynamic nominalRaw) {
    try {
      int angka = int.parse(nominalRaw.toString().replaceAll(RegExp(r'[^0-9]'), ''));
      return "Rp " + NumberFormat.decimalPattern('id').format(angka);
    } catch (e) {
      return "Rp $nominalRaw";
    }
  }

  @override
  Widget build(BuildContext context) {
    String jenisTx = (data['jenis_transaksi'] ?? 'masuk').toString().toLowerCase();
    bool isPenarikan = jenisTx.contains('keluar') || jenisTx.contains('tarik');

    String judulHalaman = isPenarikan ? "Bukti Tarik Tunai" : "Bukti Setoran Sampah";
    String tanggal = (data['tanggal_formatted'] ?? '-').toString();
    String nominalUang = formatDuitRupiah(data['nominal'] ?? '0');
    String catatan = (data['catatan'] ?? '-').toString();
    String trxId = "TRX-${data['id'] ?? '0'}";
    String namaNasabah = (data['user_name'] ?? 'Nasabah').toString();
    String namaKurir = (data['nama_kurir'] ?? 'Kurir ASRI').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
        ),
        title: Text(
          judulHalaman,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          children: [
            // ================= RECEIPT CARD =================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Green Header Section inside card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          "TRANSAKSI BERHASIL",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Bank Sampah Basayan Bestari",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          nominalUang,
                          style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 32),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trxId,
                          style: const TextStyle(color: greyTextColor, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 24),

                        _buildInfoRow("Nama Nasabah", namaNasabah),
                        const SizedBox(height: 12),
                        _buildInfoRow("Waktu Setor", tanggal),
                        const SizedBox(height: 12),
                        _buildInfoRow("Nama Kurir", namaKurir),

                        if (!isPenarikan) ...[
                          const SizedBox(height: 32),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "RINCIAN ITEM SAMPAH",
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildItemsList(),
                        ],

                        const SizedBox(height: 32),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Catatan Timbangan:",
                            style: TextStyle(color: darkTextColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FBF9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: Text(
                            catatan,
                            style: const TextStyle(color: greyTextColor, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Jagged bottom effect (Simulated with a row of circles)
                  Row(
                    children: List.generate(
                      15,
                      (index) => Expanded(
                        child: Container(
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: greyTextColor, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: const TextStyle(color: darkTextColor, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    List<dynamic> details = data['details'] ?? [];

    if (details.isEmpty) {
      // Fallback jika tidak ada data detail spesifik, tampilkan ringkasan
      return _buildItemRow(
          data['judul_dinamis'] ?? 'Setor Sampah',
          "${data['total_berat'] ?? '0'} Kg",
          formatDuitRupiah(data['nominal'] ?? '0')
      );
    }

    return Column(
      children: details.map((item) {
        String nama = (item['jenis_sampah']?['nama'] ?? item['nama'] ?? 'Sampah').toString();
        String berat = "${item['berat'] ?? '0'} Kg";
        String harga = formatDuitRupiah(item['total'] ?? (double.tryParse(item['berat'].toString()) ?? 0) * (double.tryParse(item['jenis_sampah']?['harga_per_kg'].toString() ?? '0') ?? 0));

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildItemRow(nama, berat, harga),
        );
      }).toList(),
    );
  }

  Widget _buildItemRow(String title, String subtitle, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "• $title",
              style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: greyTextColor, fontSize: 12),
            ),
          ],
        ),
        Text(
          price,
          style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
