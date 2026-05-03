import 'package:flutter/material.dart';

class ScanResult {
  final String imageUrl;
  final String analysisSummary;
  final String riskLevel;
  final List<String> ingredients;
  final DateTime scannedAt;

  ScanResult({
    required this.imageUrl,
    required this.analysisSummary,
    required this.riskLevel,
    required this.ingredients,
    required this.scannedAt,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    List<String> ingredients = [];
    if (json['ingredients'] is List) {
      ingredients = (json['ingredients'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return ScanResult(
      imageUrl: json['image_url']?.toString() ?? '',
      analysisSummary: json['analysis_summary']?.toString() ?? 'Analysis completed.',
      riskLevel: json['risk_level']?.toString() ?? 'Unknown',
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

  Color getRiskColor() {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getRiskIcon() {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Icons.check_circle;
      case 'medium':
        return Icons.warning;
      case 'high':
        return Icons.dangerous;
      default:
        return Icons.help;
    }
  }
}
