import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/scan_model.dart';
import '../../services/history_service.dart';
import '../../theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firstName = (user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!
            : (user?.email ?? 'there'))
        .split(' ')
        .first;

    return Scaffold(
      backgroundColor: LiovaColors.bg,
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('Please sign in again.'))
            : CustomScrollView(
                slivers: [
                  // ── Header ──────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi, $firstName 👋',
                                  style: LiovaText.heading1,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your skin analysis history',
                                  style: LiovaText.body,
                                ),
                              ],
                            ),
                          ),
                          // Avatar
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/profile'),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: LiovaColors.roseMid,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: LiovaColors.roseDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Scan CTA banner ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _ScanBanner(
                        onTap: () => Navigator.pushNamed(context, '/scan'),
                      ),
                    ),
                  ),

                  // ── Recent scans title ───────────────────────────────
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
                      child: Text('Recent Scans', style: LiovaText.heading2),
                    ),
                  ),

                  // ── Scans list ───────────────────────────────────────
                  StreamBuilder<List<ScanResult>>(
                    stream: HistoryService().watchHistory(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final scans = snapshot.data ?? [];
                      if (scans.isEmpty) {
                        return SliverFillRemaining(
                          child: _EmptyState(
                            onScan: () => Navigator.pushNamed(context, '/scan'),
                          ),
                        );
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _ScanCard(
                              scan: scans[i],
                              onTap: () => Navigator.pushNamed(
                                  context, '/result',
                                  arguments: scans[i]),
                            ),
                            childCount: scans.length,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
      // ── Bottom nav ──────────────────────────────────────────────────
      bottomNavigationBar: BottomNav(currentIndex: 0),
      floatingActionButton: ScanFAB(
        onPressed: () => Navigator.pushNamed(context, '/scan'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// ── Scan banner card ───────────────────────────────────────────────────────
class _ScanBanner extends StatelessWidget {
  const _ScanBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE8A598), Color(0xFFD4798A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x30E8A598), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Analyze a product',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Scan now →',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.document_scanner_outlined,
                size: 56, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

// ── Scan result card ───────────────────────────────────────────────────────
class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.scan, required this.onTap});
  final ScanResult scan;
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Color dot or Image
            if (scan.imageUrl != null && scan.imageUrl!.isNotEmpty)
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(scan.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.yourSkin.isNotEmpty ? '${scan.yourSkin} skin' : 'Analysis',
                    style: LiovaText.heading3,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(scan.createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scan.analysis,
                    style: LiovaText.body.copyWith(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                scan.suitability,
                style: LiovaText.label.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onScan});
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
            child: const Icon(Icons.document_scanner_outlined,
                size: 38, color: LiovaColors.rose),
          ),
          const SizedBox(height: 16),
          const Text('No scans yet', style: LiovaText.heading3),
          const SizedBox(height: 8),
          const Text('Scan a product to see your results',
              style: LiovaText.body),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('Scan now'),
          ),
        ],
      ),
    );
  }
}

// ── Shared bottom nav ──────────────────────────────────────────────────────
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: LiovaColors.card,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () {
                  if (currentIndex != 0) {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'History',
                selected: currentIndex == 1,
                onTap: () {
                  if (currentIndex != 1) {
                    Navigator.pushReplacementNamed(context, '/history');
                  }
                },
              ),
              // Center gap for FAB
              const SizedBox(width: 56),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                selected: currentIndex == 2,
                onTap: () {
                  if (currentIndex != 2) {
                    Navigator.pushReplacementNamed(context, '/profile');
                  }
                },
              ),
              _NavItem(
                icon: Icons.info_outline_rounded,
                label: 'About',
                selected: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? LiovaColors.rose : LiovaColors.textLight;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: LiovaText.label.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating scan button ───────────────────────────────────────────────────
class ScanFAB extends StatelessWidget {
  const ScanFAB({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [LiovaColors.rose, LiovaColors.roseDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Color(0x40E8A598), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}
