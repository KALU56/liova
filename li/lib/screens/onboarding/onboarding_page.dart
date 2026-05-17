import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.onGetStarted,
    required this.onSignIn,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiovaColors.bg,
      body: Stack(
        children: [
          // ── Background blobs ────────────────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                color: LiovaColors.roseMid,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: LiovaColors.tealPale,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Hero illustration
                  Container(
                    width: 160,
                    height: 160,
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [LiovaColors.roseMid, LiovaColors.rosePale],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.face_retouching_natural,
                      size: 80,
                      color: LiovaColors.roseDark,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // App name
                  const Text(
                    'Liova',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: LiovaColors.textDark,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tagline
                  const Text(
                    'Know what\'s in your skincare.\nGet personalized ingredient analysis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: LiovaColors.textMid,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Features row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _FeatureChip(
                          icon: Icons.camera_alt_rounded, label: 'Scan labels'),
                      const SizedBox(width: 10),
                      _FeatureChip(
                          icon: Icons.biotech_outlined,
                          label: 'AI analysis'),
                      const SizedBox(width: 10),
                      _FeatureChip(
                          icon: Icons.shield_outlined, label: 'Stay safe'),
                    ],
                  ),

                  const Spacer(flex: 3),

                  // Get started
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onGetStarted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LiovaColors.rose,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Sign in
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: onSignIn,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LiovaColors.rose,
                        side: const BorderSide(
                            color: LiovaColors.roseMid, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Disclaimer
                  const Text(
                    'AI results are for informational purposes only.\nAlways consult a dermatologist.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11, color: LiovaColors.textLight, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: LiovaColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: LiovaColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LiovaColors.rose),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: LiovaColors.textMid)),
        ],
      ),
    );
  }
}
