import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/scan_model.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  static Future<ScanResult> analyzeImage({
    required List<int> imageBytes,
    required String mimeType,
    required String skinType,
    String? imageUrl,
  }) async {
    final uri = Uri.parse('$baseUrl/analyze-image');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'image_base64': base64Encode(imageBytes),
            'mime_type': mimeType,
            'skin_type': skinType,
            'top_k': 5,
          }),
        )
        .timeout(const Duration(seconds: 70));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      return ScanResult.fromApi(jsonBody, imageUrl: imageUrl);
    }

    String message = 'Analysis failed. Please try again.';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = body['detail']?.toString();
      if (response.statusCode == 429) {
        message = 'AI quota is temporarily full. Please try again soon.';
      } else if (detail != null && detail.isNotEmpty) {
        message = detail.length > 120 ? detail.substring(0, 120) : detail;
      }
    } catch (_) {}

    throw Exception(message);
  }

  static Future<ScanResult> analyzeText({
    required String productText,
    required String skinType,
  }) async {
    final uri = Uri.parse('$baseUrl/analyze-text');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'product_text': productText,
            'skin_type': skinType,
            'top_k': 5,
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      return ScanResult.fromApi(jsonBody);
    }

    String message = 'Analysis failed. Please try again.';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = body['detail']?.toString();
      if (response.statusCode == 429) {
        message = 'AI quota is temporarily full. Please try again soon.';
      } else if (detail != null && detail.isNotEmpty) {
        message = detail.length > 120 ? detail.substring(0, 120) : detail;
      }
    } catch (_) {}

    throw Exception(message);
  }
}
