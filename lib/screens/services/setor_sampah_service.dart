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

  // ================= 4. FETCH BERAT DARI IOT =================
  static Future<double?> fetchBeratIot() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/berat-timbangan-iot'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return double.tryParse(data['berat_iot'].toString()) ?? 0.0;
      }
    } catch (e) {
      print("Error fetch berat Iot: $e");
    }
    return null;
  }

  // ================= 5. SUBMIT SETOR SAMPAH =================
  static Future<http.Response> submitSetoran({
    required int userId,
    required int kurirId,
    required int grandTotal,
    required String judulDinamis,
    required String catatan,
    int? jadwalId,
    required List<Map<String, dynamic>> sampahList,
    required String imagePath,
  }) async {
    var uri = Uri.parse('${AppConfig.baseUrl}/setor-sampah');
    var request = http.MultipartRequest('POST', uri);

    request.fields['user_id'] = userId.toString();
    request.fields['kurir_id'] = kurirId.toString();
    request.fields['grand_total'] = grandTotal.toString();
    request.fields['judul_dinamis'] = judulDinamis;
    request.fields['catatan'] = catatan;
    if (jadwalId != null && jadwalId != 0) {
      request.fields['jadwal_id'] = jadwalId.toString();
    }
    request.fields['sampah_list'] = jsonEncode(sampahList);
    request.files.add(await http.MultipartFile.fromPath('foto_sampah', imagePath));

    var streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }
}
