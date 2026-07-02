import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Returns a web-safe [http.Client].
/// On the Web, it returns a standard [http.Client] because standard network requests
/// are handled by the browser and cannot bypass SSL checks programmatically.
/// On native platforms (Android, iOS, macOS, Windows, Linux), it returns an [IOClient]
/// that configures [HttpClient] to bypass certificate validation.
http.Client getSafeClient({String? trustedHost}) {
  if (kIsWeb) {
    return http.Client();
  }
  final ioClient = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) {
      if (trustedHost != null) {
        return host == trustedHost;
      }
      return true;
    };
  return IOClient(ioClient);
}
