import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/jenis_sampah.dart';

class JenisSampahService {

  // GANTI sesuai IP laptop
  static const baseUrl =
      "http://192.168.100.48:8000/api";


  static Future<List<JenisSampah>> getData() async {

    try {

      final response = await http.get(
        Uri.parse(
          "$baseUrl/jenis-sampah",
        ),
      );


      print(
        "STATUS : ${response.statusCode}",
      );

      print(
        "BODY : ${response.body}",
      );


      if(response.statusCode != 200){
        return [];
      }


      final List data =
      jsonDecode(response.body);


      return data
          .map(
            (e) =>
            JenisSampah.fromJson(e),
      )
          .toList();

    } catch(e){

      print(
        "ERROR API : $e",
      );

      return [];
    }
  }
}