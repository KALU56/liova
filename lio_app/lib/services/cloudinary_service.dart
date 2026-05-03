import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String cloudName;
  final String uploadPreset;

  CloudinaryService({
    required this.cloudName,
    required this.uploadPreset,
  });

  Future<String> uploadImage(File imageFile) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Cloudinary upload failed: ${response.statusCode}');
    }

    final result = jsonDecode(body) as Map<String, dynamic>;
    final url = result['secure_url'] as String?;
    
    if (url == null || url.isEmpty) {
      throw Exception('No secure_url in Cloudinary response');
    }
    
    return url;
  }
}