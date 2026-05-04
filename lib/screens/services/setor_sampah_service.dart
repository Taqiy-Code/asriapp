import 'dart:convert';
import 'package:http/http.dart' as http;

class SetorSampahService {

  static const baseUrl =
      "http://192.168.100.48:8000/api";


  static Future<bool> store({

    required int userId,
    required int jenisId,
    required String catatan,

  }) async {

    try {

      final response =
      await http.post(

        Uri.parse(
          "$baseUrl/setor-sampah",
        ),

        headers: {
          "Content-Type":
          "application/json",
        },

        body: jsonEncode({

          "user_id": userId,

          "jenis_sampah_id":
          jenisId,

          "catatan":
          catatan,

        }),
      );


      return response.statusCode == 200 ||
          response.statusCode == 201;

    } catch(e){

      print(e);

      return false;
    }
  }
}