import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:asriapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'client_helper.dart';

class AuthService {
  // 🔥 1. Buat satu Client Aman yang bisa dipakai bareng-bareng oleh semua fungsi di class ini
  static http.Client get _client => getSafeClient(trustedHost: 'pht.my.id');

  // ================= FUNGSI LOGIN =================
  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/login');
    final stopwatch = Stopwatch()..start();

    // 🔥 2. Cukup panggil _client di sini
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'no_hp': phone,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 10));

    stopwatch.stop();
    print('LOGIN TIME: ${stopwatch.elapsedMilliseconds} ms');

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setInt('user_id', int.tryParse(body['user']['id'].toString()) ?? 0);
      prefs.setString('user_name', body['user']['name'].toString());
      prefs.setString('role', body['user']['role'].toString());
    }

    return {
      "status": response.statusCode,
      "data": body,
    };
  }

  // ================= CONTOH FUNGSI BARU (Misal: Register) =================
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/register');

    // 🔥 3. Fungsi baru tinggal pakai _client yang sama, otomatis bebas error SSL!
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    return {
      "status": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  // ================= FUNGSI LUPA PASSWORD =================

  // 1. Request OTP ke WhatsApp
  static Future<Map<String, dynamic>> requestOtp(String phone) async {
    final url = Uri.parse('${AppConfig.baseUrl}/password/forgot');
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'no_hp': phone}),
    );
    return {
      "status": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  // 2. Verifikasi Kode OTP
  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final url = Uri.parse('${AppConfig.baseUrl}/password/verify');
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'no_hp': phone, 'otp': otp}),
    );
    return {
      "status": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }

  // 3. Reset Password Baru
  static Future<Map<String, dynamic>> resetPassword(
      String phone, String otp, String password) async {
    final url = Uri.parse('${AppConfig.baseUrl}/password/reset');
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'no_hp': phone,
        'otp': otp,
        'password': password,
        'password_confirmation': password,
      }),
    );
    return {
      "status": response.statusCode,
      "data": jsonDecode(response.body),
    };
  }
}