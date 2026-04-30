import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/scan_model.dart';

class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;

  Future<ScanResult> analyzeImage(String imageUrl) async {
    final uri = Uri.parse('$baseUrl/analyze');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image_url': imageUrl}),
    );

    if (response.statusCode != 200) {
      throw Exception('Analysis request failed (${response.statusCode}): ${response.body}');
    }

    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    if ((jsonMap['image_url'] as String?)?.isEmpty ?? true) {
      jsonMap['image_url'] = imageUrl;
    }
    return ScanResult.fromJson(jsonMap);
  }
}
