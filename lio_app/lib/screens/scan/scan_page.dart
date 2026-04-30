import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/scan_model.dart';
import '../../services/api_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/history_service.dart';


const String _kFastApiBaseUrl = 'http://10.0.2.2:8000';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ImagePicker _picker = ImagePicker();
  late final CloudinaryService _cloudinaryService;
  final ApiService _apiService = ApiService(
    baseUrl: dotenv.env['FASTAPI_BASE_URL'] ?? _kFastApiBaseUrl,
  );
  final HistoryService _historyService = HistoryService();

  bool _isLoading = false;
  XFile? _pickedImage;
  ScanResult? _scanResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];
    if (cloudName == null || uploadPreset == null) {
      throw Exception('Cloudinary config missing in .env');
    }
    _cloudinaryService = CloudinaryService(
      cloudName: cloudName,
      uploadPreset: uploadPreset,
    );
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  Future<void> _captureAndAnalyze() async {
    setState(() {
      _errorMessage = null;
    });

    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1600,
    );

    if (photo == null) {
      return;
    }

    setState(() {
      _pickedImage = photo;
      _scanResult = null;
      _isLoading = true;
    });

    try {
      final imageFile = File(photo.path);
      final uploadedUrl = await _cloudinaryService.uploadImage(imageFile);
      final result = await _apiService.analyzeImage(uploadedUrl);
      await _historyService.addScan(result);

      if (!mounted) return;
      setState(() {
        _scanResult = result;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildResultCard() {
    if (_scanResult == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Analysis result',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Risk level: ${_scanResult!.riskLevel}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_scanResult!.imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    _scanResult!.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 10),
              Text(
                _scanResult!.analysisSummary,
                style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
              ),
              if (_scanResult!.ingredients.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Ingredients found',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _scanResult!.ingredients
                      .map(
                        (name) => Chip(
                          label: Text(name),
                          backgroundColor: const Color(0xFFF3F4F6),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Saved to scan history.',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => _handleBack(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Scan Product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Use your camera to take a picture of the product ingredients. ',
                style: TextStyle(fontSize: 16, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 8),
              const Text(
                'The image is uploaded to Cloudinary, then the FastAPI backend analyzes it and returns ingredient results. Make sure your FastAPI server is running and reachable at http://10.0.2.2:8000 when using an Android emulator.',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFF991B1B)),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              Center(
                child: _pickedImage == null
                    ? const Icon(
                        Icons.camera_alt_outlined,
                        size: 100,
                        color: Color(0xFF94A3B8),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          File(_pickedImage!.path),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const SizedBox(height: 18),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _captureAndAnalyze,
                    icon: const Icon(Icons.camera_alt_rounded, size: 20),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        _pickedImage == null ? 'Capture Product Photo' : 'Retake Photo',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
              ],
              _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }
}
