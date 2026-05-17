import 'package:cloud_firestore/cloud_firestore.dart';

class ScanResult {
  final String id;
  final String yourSkin;
  final List<String> productContains;
  final String analysis;
  final String suitability;
  final String suggestion;
  final DateTime createdAt;
  final String? imageUrl;

  const ScanResult({
    required this.id,
    required this.yourSkin,
    required this.productContains,
    required this.analysis,
    required this.suitability,
    required this.suggestion,
    required this.createdAt,
    this.imageUrl,
  });

  factory ScanResult.fromApi(Map<String, dynamic> json, {String? imageUrl}) {
    return ScanResult(
      id: '',
      yourSkin: json['your_skin']?.toString() ?? 'Unknown',
      productContains: (json['product_contains'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      analysis: json['analysis']?.toString() ?? '',
      suitability: json['suitability']?.toString() ?? 'Moderate',
      suggestion: json['suggestion']?.toString() ?? '',
      createdAt: DateTime.now(),
      imageUrl: imageUrl,
    );
  }

  factory ScanResult.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final timestamp = data['created_at'];
    return ScanResult(
      id: doc.id,
      yourSkin: data['your_skin']?.toString() ?? 'Unknown',
      productContains: (data['product_contains'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      analysis: data['analysis']?.toString() ?? '',
      suitability: data['suitability']?.toString() ?? 'Moderate',
      suggestion: data['suggestion']?.toString() ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      imageUrl: data['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'your_skin': yourSkin,
      'product_contains': productContains,
      'analysis': analysis,
      'suitability': suitability,
      'suggestion': suggestion,
      'created_at': FieldValue.serverTimestamp(),
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}
