import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/history_service.dart';
import '../models/scan_model.dart';

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService();
});

final historyControllerProvider = FutureProvider<List<ScanResult>>((ref) {
  final historyService = ref.watch(historyServiceProvider);
  return historyService.loadHistory();
});

final historyClearControllerProvider = Provider<HistoryClearController>((ref) {
  return HistoryClearController(ref.watch(historyServiceProvider));
});

class HistoryClearController {
  HistoryClearController(this._historyService);
  
  final HistoryService _historyService;

  Future<void> clearHistory() async {
    await _historyService.clearHistory();
  }

  Future<void> deleteScan(int index) async {
    await _historyService.deleteScan(index);
  }
}
