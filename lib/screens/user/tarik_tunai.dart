import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../services/setor_sampah_service.dart';
import 'success_withdrawal_page.dart';


const primaryColor = Color(0xFF1E521E);
const softGreenColor = Color(0xFFE8F5E9);
const backgroundColor = Color(0xFFF9FBF9);
const darkTextColor = Color(0xFF0D240D);
const greyTextColor = Color(0xFF555555);

class TarikTunaiPage extends StatefulWidget {
  const TarikTunaiPage({super.key});

  @override
  State<TarikTunaiPage> createState() => _TarikTunaiPageState();
}

class _TarikTunaiPageState extends State<TarikTunaiPage> {
  int _saldo = 0;
  int _nominal = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _userId = 0;

  final TextEditingController _nominalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      if (prefs.containsKey('user_id')) {
        final rawId = prefs.get('user_id');
        if (rawId is int) {
          _userId = rawId;
        } else if (rawId is String) {
          _userId = int.tryParse(rawId) ?? 0;
        }
      }

      if (_userId == 0) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/dashboard-nasabah/$_userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _saldo = int.tryParse(data['nasabah']['saldo'].toString()) ?? 0;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetch user data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _setNominal(int value) {
    setState(() {
      _nominal = value;
      _nominalController.text = value.toString();
    });
  }

  String _selectedMethod = "DANA";
  final List<String> _methods = ["DANA", "OVO", "GOPAY", "PULSA"];
  final TextEditingController _phoneController = TextEditingController();

  Future<void> _prosesTarikTunai() async {
    if (_nominal <= 0) {
      _showPesan("Silakan masukkan nominal penarikan.", Colors.red);
      return;
    }

    if (_phoneController.text.length < 10) {
      _showPesan("Silakan masukkan nomor HP yang valid.", Colors.red);
      return;
    }

    if (_nominal > _saldo) {
      // TAMPILKAN POP-UP JIKA SALDO TIDAK CUKUP
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text("Saldo Kurang", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            "Maaf, saldo tabungan Anda saat ini (${_formatRupiah(_saldo)}) tidak mencukupi untuk melakukan penarikan sebesar ${_formatRupiah(_nominal)}.",
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await SetorSampahService.tarikTunai(
        userId: _userId,
        nominal: _nominal,
        metode: _selectedMethod,
        nomorHp: _phoneController.text,
      );


// ... (kode lainnya tetap sama) ...

      if (result['status'] == 200) {
        if (mounted) {
          // Gunakan ID asli dari database
          String realId = result['data']['transaction_id'] ?? "TRX-${DateTime.now().millisecondsSinceEpoch}";
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SuccessWithdrawalPage(
                nominal: _nominal,
                transactionId: realId,
                method: _selectedMethod,
                phone: _phoneController.text,
              ),
            ),
          );
        }
      } else {
        _showPesan(result['data']['message'] ?? "Gagal memproses penarikan.", Colors.red);
      }
    } catch (e) {
      _showPesan("Terjadi kesalahan koneksi.", Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showPesan(String pesan, Color warna) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatRupiah(int angka) {
    return "Rp " + NumberFormat.decimalPattern('id').format(angka);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
        ),
        title: const Text("Tarik Tunai", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD SALDO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryColor, Color(0xFF2E6B2E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text("Saldo Tabungan Anda", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          _formatRupiah(_saldo),
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text("Metode Penarikan", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: darkTextColor)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedMethod,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                    items: _methods.map((method) => DropdownMenuItem(value: method, child: Text(method))).toList(),
                    onChanged: (val) => setState(() => _selectedMethod = val!),
                  ),

                  const SizedBox(height: 24),
                  const Text("Nomor HP Tujuan", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: darkTextColor)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "08xxxxxxxxxx",
                      prefixIcon: const Icon(Icons.phone_android_rounded, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryColor, width: 2)),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text("Masukkan Nominal", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: darkTextColor)),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _nominalController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setState(() {
                        _nominal = int.tryParse(val) ?? 0;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Contoh: 10000",
                      errorText: (_nominal > _saldo) ? "Saldo Anda tidak mencukupi" : null,
                      errorStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      prefixIcon: const Icon(Icons.payments_rounded, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: (_nominal > _saldo) ? Colors.red : primaryColor, width: 2)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // QUICK OPTIONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _quickOption(5000),
                      _quickOption(10000),
                      _quickOption(20000),
                      _quickOption(50000),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // RINGKASAN
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: softGreenColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _summaryRow("Jumlah Penarikan", _formatRupiah(_nominal)),
                        const SizedBox(height: 8),
                        _summaryRow("Biaya Admin", "Rp 0"),
                        const Divider(height: 24),
                        _summaryRow("Total Diterima", _formatRupiah(_nominal), isBold: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _prosesTarikTunai,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Tarik Tunai Sekarang", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _quickOption(int value) {
    bool isSelected = _nominal == value;
    return InkWell(
      onTap: () => _setNominal(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
        ),
        child: Text(
          NumberFormat.compact().format(value),
          style: TextStyle(color: isSelected ? Colors.white : darkTextColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: greyTextColor, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(color: darkTextColor, fontSize: 14, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700)),
      ],
    );
  }
}
