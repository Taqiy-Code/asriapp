import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:asriapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JadwalService {
  static http.Client get _client {
    final ioClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  // ================= GET JADWAL KURIR =================
  static Future<List<dynamic>> getJadwalKurir(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final url = Uri.parse('${AppConfig.baseUrl}/kurir/jadwal/$id');
      final response = await _client.get(
        url,
        headers: {
          "Accept": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );
      final body = jsonDecode(response.body);

      if (body is Map && body.containsKey('data')) {
        return body['data'] ?? [];
      } else if (body is List) {
        return body;
      }
      return [];
    } catch (e) {
      debugPrint('GET JADWAL KURIR ERROR: $e');
      return [];
    }
  }

  // ================= MULAI JEMPUT (SINKRON DENGAN ENUM DB) =================
  static Future<Map<String, dynamic>> mulaiJemput(int jadwalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      // 🔥 SINKRONISASI ENUM: Database Anda hanya menerima: 'terjadwal', 'proses', 'selesai', 'batal'
      final Map<String, dynamic> requestBody = {'status': 'proses'};

      final List<Map<String, dynamic>> attempts = [
        {
          'url': '${AppConfig.baseUrl}/jadwal-penjemputan/$jadwalId/mulai',
          'method': 'POST',
        },
        {
          'url': '${AppConfig.baseUrl}/jadwal-penjemputan/$jadwalId',
          'method': 'PUT', // Standar Laravel Update (Resource)
        },
        {
          'url': '${AppConfig.baseUrl}/kurir/mulai-jemput/$jadwalId',
          'method': 'POST',
        },
      ];

      http.Response? lastResponse;

      for (var attempt in attempts) {
        final url = Uri.parse(attempt['url']);
        final String method = attempt['method'];

        debugPrint("MENCOBA UPDATE STATUS ($method): $url");

        try {
          http.Response response;
          if (method == 'POST') {
            response = await _client.post(url, headers: headers, body: jsonEncode(requestBody));
          } else {
            response = await _client.put(url, headers: headers, body: jsonEncode(requestBody));
          }

          lastResponse = response;
          debugPrint("HASIL -> ${response.statusCode} : ${response.body}");

          if (response.statusCode == 200 || response.statusCode == 201) {
            return {"success": true, "message": "Status berhasil diubah menjadi PROSES."};
          }
        } catch (e) {
          debugPrint("GAGAL KE $url: $e");
        }
      }

      // Diagnosis Error Berdasarkan Log Terakhir
      String errorMsg = "Gagal memperbarui status.";
      if (lastResponse != null) {
        if (lastResponse.statusCode == 500) {
          if (lastResponse.body.contains("Data truncated")) {
            errorMsg = "Server Error (500): Database menolak status baru. Hubungi Admin untuk memperbaiki Controller Laravel (Ubah 'dalam_perjalanan' jadi 'proses').";
          } else {
            errorMsg = "Server Error (500): Terjadi kesalahan logika di Backend.";
          }
        } else if (lastResponse.statusCode == 404) {
          errorMsg = "Rute API tidak ditemukan (404). Silakan periksa file routes/api.php di server.";
        } else {
          try {
            final errBody = jsonDecode(lastResponse.body);
            errorMsg = errBody['message'] ?? "Gagal: Status ${lastResponse.statusCode}";
          } catch (_) {
            errorMsg = "Gagal: Status ${lastResponse.statusCode}";
          }
        }
      }

      return {"success": false, "message": errorMsg};
    } catch (e) {
      return {"success": false, "message": "Kesalahan Sistem: $e"};
    }
  }

  // ================= GET JADWAL AKTIF NASABAH =================
  static Future<Map<String, dynamic>?> getJadwalNasabah(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final url = Uri.parse('${AppConfig.baseUrl}/nasabah/jadwal/$id');
      final response = await _client.get(
        url,
        headers: {
          "Accept": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'];
      }
      return null;
    } catch (e) {
      debugPrint('GET JADWAL NASABAH ERROR: $e');
      return null;
    }
  }
}