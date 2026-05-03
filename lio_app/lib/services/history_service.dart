import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_model.dart';

class HistoryService {
  static const String _historyKey = 'scan_history';
  static const int _maxHistorySize = 30;

  Future<List<ScanResult>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_historyKey) ?? [];
    
    final results = <ScanResult>[];
    for (final item in saved) {
      try {
        final jsonMap = jsonDecode(item) as Map<String, dynamic>;
        results.add(ScanResult.fromJson(jsonMap));
      } catch (_) {
        // Skip invalid entries
      }
    }
    
    // Sort by date (newest first)
    results.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    
    return results;
  }

  Future<void> addScan(ScanResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    
    // Add to beginning
    history.insert(0, jsonEncode(result.toJson()));
    
    // Limit size
    if (history.length > _maxHistorySize) {
      history.removeRange(_maxHistorySize, history.length);
    }
    
    await prefs.setStringList(_historyKey, history);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> deleteScan(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    
    if (index < history.length) {
      history.removeAt(index);
      await prefs.setStringList(_historyKey, history);
    }
  }
}