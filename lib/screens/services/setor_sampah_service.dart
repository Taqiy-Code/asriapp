import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:asriapp/config.dart';

class SetorSampahService {
  // ================= 1. CREATE REQUEST PENJEMPUTAN (NASABAH) =================
  static Future<bool> store({
    required int userId,
    required List<int> jenisIds,
    required String catatan,
  }) async {
    try {
      final items = jenisIds.map((id) => {
        "jenis_sampah_id": id,
        "berat": 0,
      }).toList();

      final url = Uri.parse('${AppConfig.baseUrl}/request-penjemputan');
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "user_id": userId,
          "catatan": catatan,
          "items": items,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // ================= 2. READ RIWAYAT TRANSAKSI (NASABAH) - FIXED =================
  static Future<List<dynamic>> getRiwayat({required int userId}) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/dashboard-nasabah/$userId');
      print('GET REQUEST RIWAYAT VIA: $url');

      final response = await http.get(
        url,
        headers: {"Accept": "application/json"},
      );

      print('GET STATUS RIWAYAT : ${response.statusCode}');
      print('GET BODY RIWAYAT : ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['riwayat_mutasi'] != null) {
          return body['riwayat_mutasi'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      print('GET ERROR RIWAYAT : $e');
      return [];
    }
  }

  // ================= 3. AUTOLOAD MANIFES REQUEST (UNTUK KURIR) =================
  static Future<Map<String, dynamic>?> getRequestDetail(int nasabahId) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/request-detail/$nasabahId');
      final response = await http.get(
        url,
        headers: {"Accept": "application/json"},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return body;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}