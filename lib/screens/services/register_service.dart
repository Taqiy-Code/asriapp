import 'dart:convert';
import 'dart:io';

import 'package:asriapp/config.dart';
import 'package:http/http.dart' as http;
import '../models/bank_sampah_model.dart';
import 'client_helper.dart';

class RegisterService {
  static http.Client get _client => getSafeClient();

  static Future<List<BankSampahModel>> getBankSampah() async {
    try {
      // Menggunakan AppConfig.baseUrl dan _client agar aman dari error SSL
      final url = Uri.parse('${AppConfig.baseUrl}/bank-sampah');
      final response = await _client.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List data = [];
        
        // Menangani jika response adalah List langsung atau terbungkus dalam field 'data'
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded['data'] != null) {
          data = decoded['data'];
        }

        return data.map((e) => BankSampahModel.fromJson(e)).toList();
      } else {
        throw Exception('Gagal memuat data dari server (${response.statusCode})');
      }
    } catch (e) {
      print('Error Get Bank Sampah: $e');
      return []; // Mengembalikan list kosong alih-alih rethrow agar aplikasi tidak crash
    }
  }
  static Future<Map<String, dynamic>> register({
    required String name,
    required String password,
    required String confirmPassword,
    required String phone,
    required String address,
    required int bankSampahId,
    File? foto,
  }) async {
    try {
      final uri = Uri.parse("${AppConfig.baseUrl}/register");
      final request = http.MultipartRequest("POST", uri);

      request.fields.addAll({
        "name": name,
        "password": password,
        "password_confirmation": confirmPassword,
        "no_hp": phone,
        "alamat": address,
        "bank_sampah_id": bankSampahId.toString(),
      });


      if (

      foto != null

      ) {

        request.files.add(

          await http
              .MultipartFile
              .fromPath(

            "foto",

            foto.path,
          ),
        );
      }


      final response = await _client.send(request);

      final body = await response.stream.bytesToString();


      final data =

      jsonDecode(
        body,
      );


      return {

        "status":

        response
            .statusCode,

        "data":
        data,
      };

    } catch (e) {

      return {

        "status": 500,

        "data": {

          "message":
          e.toString(),
        },
      };
    }
  }
}