import 'dart:convert';

class ScanResult {
  const ScanResult({
    required this.imageUrl,
    required this.analysisSummary,
    required this.riskLevel,
    required this.ingredients,
    required this.scannedAt,
  });

  final String imageUrl;
  final String analysisSummary;
  final String riskLevel;
  final List<String> ingredients;
  final DateTime scannedAt;

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final ingredientsRaw = json['ingredients'];
    final ingredients = <String>[];
    if (ingredientsRaw is List) {
      ingredients.addAll(ingredientsRaw.map((element) => element.toString()));
    }

    return ScanResult(
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString() ?? '',
      analysisSummary: json['analysis_summary']?.toString() ?? json['summary']?.toString() ?? 'Analysis completed.',
      riskLevel: json['risk_level']?.toString() ?? json['riskLevel']?.toString() ?? 'Unknown',
      ingredients: ingredients,
      scannedAt: DateTime.tryParse(json['scanned_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
      'analysis_summary': analysisSummary,
      'risk_level': riskLevel,
      'ingredients': ingredients,
      'scanned_at': scannedAt.toIso8601String(),
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}
