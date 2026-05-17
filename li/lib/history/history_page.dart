import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/scan_model.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../screens/home/home_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: LiovaColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('History', style: LiovaText.heading1),
                        SizedBox(height: 4),
                        Text('Your past scans', style: LiovaText.body),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: LiovaColors.rosePale,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: LiovaColors.roseMid),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list_rounded,
                            size: 16, color: LiovaColors.rose),
                        const SizedBox(width: 4),
                        Text('Filter',
                            style: LiovaText.label
                                .copyWith(color: LiovaColors.rose)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────────
            Expanded(
              child: user == null
                  ? const Center(child: Text('Please sign in again.'))
                  : StreamBuilder<List<ScanResult>>(
                      stream: HistoryService().watchHistory(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: LiovaColors.rose));
                        }
                        final scans = snapshot.data ?? [];
                        if (scans.isEmpty) {
                          return _HistoryEmpty(
                            onScan: () =>
                                Navigator.pushNamed(context, '/scan'),
                          );
                        }
                        return ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: scans.length,
                          itemBuilder: (ctx, i) => _HistoryCard(
                            scan: scans[i],
                            index: i,
                            onTap: () => Navigator.pushNamed(
                                context, '/result',
                                arguments: scans[i]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(currentIndex: 1),
      floatingActionButton: ScanFAB(
        onPressed: () => Navigator.pushNamed(context, '/scan'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// ── History card ──────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  const _HistoryCard(
      {required this.scan, required this.index, required this.onTap});
  final ScanResult scan;
  final int index;
  final VoidCallback onTap;

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    
    String datePart;
    if (date == today) {
      datePart = 'Today';
    } else if (date == today.subtract(const Duration(days: 1))) {
      datePart = 'Yesterday';
    } else {
      datePart = '${dt.day}/${dt.month}/${dt.year}';
    }

    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    
    return '$datePart, $hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final color = suitabilityColor(scan.suitability);
    final bgColor = suitabilityBgColor(scan.suitability);
    final emoji = suitabilityEmoji(scan.suitability);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: LiovaDecorations.card(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left color strip
                Container(
                  width: 5,
                  color: color,
                ),
                // Thumbnail
                if (scan.imageUrl != null && scan.imageUrl!.isNotEmpty)
                  Container(
                    width: 60,
                    height: double.infinity,
                    margin: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: NetworkImage(scan.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(scan.imageUrl != null ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scan.yourSkin.isNotEmpty
                                        ? '${scan.yourSkin} skin'
                                        : 'Scan #${index + 1}',
                                    style: LiovaText.heading3,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDateTime(scan.createdAt),
                                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$emoji ${scan.suitability}',
                                style: LiovaText.label
                                    .copyWith(color: color),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          scan.analysis,
                          style: LiovaText.body.copyWith(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          scan.suggestion,
                          style: const TextStyle(
                            fontSize: 12,
                            color: LiovaColors.teal,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_right_rounded,
                      color: LiovaColors.textLight),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────
class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({required this.onScan});
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: LiovaColors.rosePale,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded,
                size: 38, color: LiovaColors.rose),
          ),
          const SizedBox(height: 16),
          const Text('No history yet', style: LiovaText.heading3),
          const SizedBox(height: 8),
          const Text('Your past scans will appear here',
              style: LiovaText.body),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: const Text('Scan a product'),
          ),
        ],
      ),
    );
  }
}
