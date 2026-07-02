import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:asriapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'client_helper.dart';

class SetorSampahService {
  // 🔥 1. CLIENT AMAN UNTUK HOSTING (Bebas SSL Error)
  static http.Client get _client => getSafeClient(trustedHost: 'pht.my.id');

  // ================= 1. CREATE REQUEST PENJEMPUTAN (NASABAH) =================
  static Future<bool> store({
    required int userId,
    required List<int> jenisIds,
    required String catatan,
  }) async {
    try {
      final items = jenisIds.map((id) => {
        "jenis_sampah_id": id,
        "berat": 0.0,
      }).toList();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final url = Uri.parse('${AppConfig.baseUrl}/request-penjemputan');

      print("DEBUG STORE REQUEST: URL=$url");
      print("DEBUG STORE REQUEST: USER_ID=$userId");
      print("DEBUG STORE REQUEST: TOKEN=${token.isNotEmpty ? 'EXISTS' : 'EMPTY'}");

      final response = await _client.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "user_id": userId,
          "catatan": catatan,
          "items": items,
        }),
      );

      print("DEBUG STORE RESPONSE: ${response.statusCode} - ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("DEBUG STORE EXCEPTION: $e");
      return false;
    }
  }

  // ================= 2. READ RIWAYAT TRANSAKSI (NASABAH) =================
  static Future<List<dynamic>> getRiwayat({required int userId}) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/dashboard-nasabah/$userId');
      final response = await _client.get(
        url,
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['riwayat_mutasi'] != null) {
          return body['riwayat_mutasi'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ================= 3. AUTOLOAD MANIFES REQUEST (UNTUK KURIR) =================
  static Future<Map<String, dynamic>?> getRequestDetail(int nasabahId) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/request-detail/$nasabahId');
      final response = await _client.get(
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

  // ================= AMBIL BERAT TIMBANGAN IOT =================
  static Future<double?> fetchBeratIot() async {
    try {
      final response = await _client.get(Uri.parse('${AppConfig.baseUrl}/berat-timbangan-iot'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return double.tryParse(data['berat_iot'].toString()) ?? 0.0;
      }
    } catch (e) {
      print("Error fetch berat Iot: $e");
    }
    return null;
  }

  // ================= 🔄 PATCH: SUBMIT TIMBANGAN DARI JADWAL ADMIN =================
  static Future<http.Response> submitSetoranJadwalAdmin({
    required int id, // ID Transaksi Induk/Setor terkait
    required int userId,
    required int kurirId,
    required int grandTotal,
    required String catatan,
    int? jadwalId,
    required List<Map<String, dynamic>> sampahList,
    required String imagePath,
  }) async {
    var uri = Uri.parse('${AppConfig.baseUrl}/setor-sampah/jadwal-admin/$id');

    // 🛠️ Perubahan Utama: Gunakan method 'PATCH' untuk MultipartRequest
    var request = http.MultipartRequest('PATCH', uri);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    request.headers['Accept'] = 'application/json';
    if (token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['user_id'] = userId.toString();
    request.fields['kurir_id'] = kurirId.toString();
    request.fields['grand_total'] = grandTotal.toString();
    request.fields['catatan'] = catatan;
    if (jadwalId != null && jadwalId != 0) {
      request.fields['jadwal_id'] = jadwalId.toString();
    }
    request.fields['sampah_list'] = jsonEncode(sampahList);

    print("DEBUG PATCH JADWAL ADMIN: fields=${request.fields}");

    if (imagePath.isNotEmpty && imagePath.trim() != "") {
      request.files.add(await http.MultipartFile.fromPath('foto_sampah', imagePath));
    }

    var streamedResponse = await _client.send(request);
    var response = await http.Response.fromStream(streamedResponse);

    print("DEBUG PATCH JADWAL ADMIN RESPONSE: ${response.statusCode} - ${response.body}");
    return response;
  }

  // ================= 🔄 PATCH: SUBMIT TIMBANGAN DARI REQUEST NASABAH =================
  static Future<http.Response> submitSetoranRequestNasabah({
    required int setorSampahId,
    required int userId,
    required int kurirId,
    required int grandTotal,
    required String catatan,
    required List<Map<String, dynamic>> sampahList,
    required String imagePath,
  }) async {
    var uri = Uri.parse('${AppConfig.baseUrl}/setor-sampah/request-nasabah/$setorSampahId');

    // 🛠️ Perubahan Utama: Gunakan method 'PATCH' untuk MultipartRequest
    var request = http.MultipartRequest('PATCH', uri);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    request.headers['Accept'] = 'application/json';
    if (token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['user_id'] = userId.toString();
    request.fields['kurir_id'] = kurirId.toString();
    request.fields['grand_total'] = grandTotal.toString();
    request.fields['catatan'] = catatan;
    request.fields['sampah_list'] = jsonEncode(sampahList);

    print("DEBUG PATCH REQUEST NASABAH: fields=${request.fields}");

    if (imagePath.isNotEmpty && imagePath.trim() != "") {
      request.files.add(await http.MultipartFile.fromPath('foto_sampah', imagePath));
    }

    var streamedResponse = await _client.send(request);
    var response = await http.Response.fromStream(streamedResponse);

    print("DEBUG PATCH REQUEST NASABAH RESPONSE: ${response.statusCode} - ${response.body}");
    return response;
  }

  // ================= 6. TARIK TUNAI SALDO =================
  static Future<Map<String, dynamic>> tarikTunai({
    required int userId,
    required int nominal,
    required String metode,
    required String nomorHp,
    required String pin,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/tarik-tunai');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await _client.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "user_id": userId,
          "nominal": nominal,
          "metode": metode,
          "nomor_hp": nomorHp,
          "pin": pin,
        }),
      );

      return {
        "status": response.statusCode,
        "data": jsonDecode(response.body),
      };
    } catch (e) {
      return {
        "status": 500,
        "data": {"message": "Gagal terhubung ke server: $e"},
      };
    }
  }

  // ================= 7. SETUP PIN PERTAMA KALI =================
  static Future<Map<String, dynamic>> setupPin({
    required String pin,
    required String pinConfirmation,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/setup-pin');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await _client.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "pin": pin,
          "pin_confirmation": pinConfirmation,
        }),
      );

      return {
        "status": response.statusCode,
        "data": jsonDecode(response.body),
      };
    } catch (e) {
      return {
        "status": 500,
        "data": {"message": "Kesalahan: $e"},
      };
    }
  }
}