import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scan_model.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<ScanResult> analyzeImage(String imageUrl) async {
    final uri = Uri.parse('$baseUrl/analyze');
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image_url': imageUrl}),
    );

    if (response.statusCode != 200) {
      throw Exception('Analysis failed: ${response.statusCode} - ${response.body}');
    }

    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    
    // Ensure image_url is set
    if ((jsonMap['image_url'] as String?)?.isEmpty ?? true) {
      jsonMap['image_url'] = imageUrl;
    }
    
    return ScanResult.fromJson(jsonMap);
  }

  Future<Map<String, dynamic>> evaluateIngredients(List<String> ingredients) async {
    final uri = Uri.parse('$baseUrl/evaluate');
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ingredients': ingredients}),
    );

    if (response.statusCode != 200) {
      throw Exception('Evaluation failed: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<bool> healthCheck() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}