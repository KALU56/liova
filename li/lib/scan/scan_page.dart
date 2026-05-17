import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/scan_model.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  final _historyService = HistoryService();
  final _textController = TextEditingController();
  bool _loading = false;
  String? _error;
  String _skinType = 'Unknown';

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _textController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveAndOpen(ScanResult result) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    var historySaved = true;
    if (uid != null) {
      try {
        await _historyService.addScan(uid, result);
      } catch (_) {
        historySaved = false;
      }
    }
    if (!mounted) return;
    Navigator.pushNamed(context, '/result', arguments: result);
    if (!historySaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analysis shown, but history was not saved.')),
      );
    }
  }

  Future<void> _runAnalysis(Future<ScanResult> Function() task) async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await task();
      await _saveAndOpen(result);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    await _runAnalysis(() async {
      final bytes = await picked.readAsBytes();
      final imageUrl = await CloudinaryService.uploadImage(bytes, picked.name);
      return ApiService.analyzeImage(
        imageBytes: bytes,
        mimeType: picked.mimeType ?? 'image/jpeg',
        skinType: _skinType,
        imageUrl: imageUrl,
      );
    });
  }

  Future<void> _analyzeText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() { _error = 'Enter product ingredients or description.'; });
      return;
    }
    await _runAnalysis(() => ApiService.analyzeText(productText: text, skinType: _skinType));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiovaColors.bg,
      appBar: AppBar(
        title: const Text('Analyze Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Skin type selector ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your skin type', style: LiovaText.heading3),
                const SizedBox(height: 10),
                _SkinTypePicker(
                  selected: _skinType,
                  onChanged: _loading ? null : (v) => setState(() => _skinType = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Tab bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: LiovaColors.rosePale,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: LiovaColors.rose,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: LiovaColors.textMid,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: '📷  Camera / Gallery'),
                  Tab(text: '📋  Paste Text'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Tab content ──────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Camera / Gallery tab
                _ImageTab(loading: _loading, onPick: _pickAndAnalyze),
                // Text tab
                _TextTab(
                  controller: _textController,
                  loading: _loading,
                  onAnalyze: _analyzeText,
                ),
              ],
            ),
          ),

          // ── Loading / Error ──────────────────────────────────────────
          if (_loading)
            const LinearProgressIndicator(
              color: LiovaColors.rose,
              backgroundColor: LiovaColors.rosePale,
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LiovaColors.notGoodBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: LiovaColors.notGood, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            color: LiovaColors.notGood, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Skin type chips ────────────────────────────────────────────────────────
class _SkinTypePicker extends StatelessWidget {
  const _SkinTypePicker({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String>? onChanged;

  static const _types = ['Unknown', 'Dry', 'Normal', 'Oily', 'Sensitive', 'Combination'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _types.map((type) {
          final isSelected = type == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: onChanged == null ? null : () => onChanged!(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? LiovaColors.rose : LiovaColors.rosePale,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? LiovaColors.rose : LiovaColors.roseMid,
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    color: isSelected ? Colors.white : LiovaColors.textMid,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Image tab ─────────────────────────────────────────────────────────────
class _ImageTab extends StatelessWidget {
  const _ImageTab({required this.loading, required this.onPick});
  final bool loading;
  final void Function(ImageSource) onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Dashed upload area
          GestureDetector(
            onTap: loading ? null : () => onPick(ImageSource.gallery),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: LiovaColors.rosePale,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: LiovaColors.roseMid, width: 1.5,
                    style: BorderStyle.solid),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 48, color: LiovaColors.rose),
                    SizedBox(height: 12),
                    Text('Tap to upload from gallery',
                        style: TextStyle(
                            color: LiovaColors.rose,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    SizedBox(height: 4),
                    Text('or use camera below',
                        style: TextStyle(
                            color: LiovaColors.textLight, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: loading ? null : () => onPick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Open Camera'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Point your camera at a product label to analyze ingredients',
            textAlign: TextAlign.center,
            style: LiovaText.caption,
          ),
        ],
      ),
    );
  }
}

// ── Text tab ───────────────────────────────────────────────────────────────
class _TextTab extends StatelessWidget {
  const _TextTab({
    required this.controller,
    required this.loading,
    required this.onAnalyze,
  });
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              enabled: !loading,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Paste ingredients or product description here...',
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onAnalyze,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Analyze Ingredients'),
            ),
          ),
        ],
      ),
    );
  }
}
