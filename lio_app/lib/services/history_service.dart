import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_model.dart';

class HistoryService {
  static const _historyKey = 'scan_history';

  Future<List<ScanResult>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_historyKey) ?? [];
    final results = <ScanResult>[];

    for (final item in saved) {
      try {
        final jsonMap = jsonDecode(item) as Map<String, dynamic>;
        results.add(ScanResult.fromJson(jsonMap));
      } catch (_) {
        // Ignore invalid entries.
      }
    }

    return results;
  }

  Future<void> addScan(ScanResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    history.insert(0, jsonEncode(result.toJson()));
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }
    await prefs.setStringList(_historyKey, history);
  }
}
