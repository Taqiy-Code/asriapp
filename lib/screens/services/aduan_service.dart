import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:asriapp/config.dart';

class AduanService {
  // ================= 1. KIRIM ADUAN BARU =================
  static Future<Map<String, dynamic>> kirimAduan({
    required int userId,
    required String role,
    required String kategori,
    required String isi,
    File? foto,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/aduan');
      var request = http.MultipartRequest('POST', url);

      request.fields['user_id'] = userId.toString();
      request.fields['role_pengirim'] = role;
      request.fields['kategori_aduan'] = kategori;
      request.fields['isi_aduan'] = isi;

      if (foto != null) {
        request.files.add(await http.MultipartFile.fromPath('foto_bukti', foto.path));
      }

      // Gunakan timeout agar tidak loading selamanya jika server bermasalah
      var streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      var response = await http.Response.fromStream(streamedResponse);

      print("ADUAN DEBUG: ${response.statusCode} - ${response.body}");

      return {
        "status": response.statusCode,
        "data": jsonDecode(response.body),
      };
    } catch (e) {
      print("ADUAN ERROR: $e");
      return {
        "status": 500,
        "data": {"message": "Gagal terhubung ke server: $e"},
      };
    }
  }

  // ================= 2. AMBIL RIWAYAT ADUAN =================
  static Future<List<dynamic>> getRiwayat(int userId) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/aduan/riwayat/$userId');
      final response = await http.get(url, headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error fetch riwayat aduan: $e");
      return [];
    }
  }
}
