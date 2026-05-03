import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/cloudinary_service.dart';
import '../services/history_service.dart';
import '../models/scan_model.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  const baseUrl = String.fromEnvironment('FASTAPI_BASE_URL', defaultValue: 'http://10.0.2.2:8000');
  return ApiService(baseUrl: baseUrl);
});

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  const cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  const uploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');
  return CloudinaryService(cloudName: cloudName, uploadPreset: uploadPreset);
});

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService();
});

final scanControllerProvider = StateNotifierProvider<ScanController, AsyncValue<ScanResult?>>((ref) {
  return ScanController(
    apiService: ref.watch(apiServiceProvider),
    cloudinaryService: ref.watch(cloudinaryServiceProvider),
    historyService: ref.watch(historyServiceProvider),
  );
});

class ScanController extends StateNotifier<AsyncValue<ScanResult?>> {
  ScanController({
    required this.apiService,
    required this.cloudinaryService,
    required this.historyService,
  }) : super(const AsyncData(null));

  final ApiService apiService;
  final CloudinaryService cloudinaryService;
  final HistoryService historyService;

  Future<ScanResult?> analyzeImage(File imageFile) async {
    state = const AsyncLoading();
    
    try {
      // Upload to Cloudinary
      final imageUrl = await cloudinaryService.uploadImage(imageFile);
      
      // Analyze with backend
      final result = await apiService.analyzeImage(imageUrl);
      
      // Save to history
      await historyService.addScan(result);
      
      state = AsyncData(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}