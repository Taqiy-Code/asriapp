import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:asriapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tarik_tunai_model.dart';
import 'client_helper.dart';

class TarikTunaiService {
  final String baseUrl = AppConfig.baseUrl;

  http.Client _getClient() => getSafeClient();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 1. Nasabah: Membuat Request Tarik Tunai
  Future<Map<String, dynamic>> createRequestTarik({required int jumlahNominal}) async {
    final url = Uri.parse('$baseUrl/tarik-tunai');
    final client = _getClient();
    final token = await _getToken();

    try {
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'jumlah_nominal': jumlahNominal,
        }),
      );

      return {
        'success': response.statusCode == 201,
        'message': jsonDecode(response.body)['message'] ?? 'Terjadi kesalahan',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    } finally {
      client.close();
    }
  }

  // 2. Admin/Nasabah: Mengambil Daftar Request
  // Bisa difilter status=pending
  Future<List<TarikTunaiModel>> getRequests({String? status}) async {
    String urlString = '$baseUrl/tarik-tunai';
    if (status != null) urlString += '?status=$status';

    final url = Uri.parse(urlString);
    final client = _getClient();
    final token = await _getToken();

    try {
      final response = await client.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => TarikTunaiModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    } finally {
      client.close();
    }
  }

  // 3. Admin: Approve Request
  Future<bool> approveRequest(int id) async {
    final url = Uri.parse('$baseUrl/tarik-tunai/$id/approve');
    final client = _getClient();
    final token = await _getToken();

    try {
      final response = await client.patch(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    } finally {
      client.close();
    }
  }

  // 4. Admin/Nasabah: Reject/Batal Request
  Future<bool> rejectRequest(int id) async {
    final url = Uri.parse('$baseUrl/tarik-tunai/$id/reject');
    final client = _getClient();
    final token = await _getToken();

    try {
      final response = await client.patch(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    } finally {
      client.close();
    }
  }
}