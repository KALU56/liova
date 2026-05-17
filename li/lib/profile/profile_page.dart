import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../screens/home/home_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'User';
    final email = user?.email ?? '';
    final initials = name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: LiovaColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            // ── Avatar + name ──────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [LiovaColors.rose, LiovaColors.roseDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials.isNotEmpty ? initials : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(name, style: LiovaText.heading2),
                  const SizedBox(height: 4),
                  Text(email, style: LiovaText.body),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Info section ───────────────────────────────────────────
            _SectionTitle('Account Info'),
            const SizedBox(height: 10),
            _ProfileRow(
                icon: Icons.person_outline_rounded, label: 'Name', value: name),
            _ProfileRow(
                icon: Icons.email_outlined, label: 'Email', value: email),

            const SizedBox(height: 28),
            _SectionTitle('Preferences'),
            const SizedBox(height: 10),
            _ProfileTile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: LiovaColors.rose,
              ),
            ),
            _ProfileTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: LiovaColors.textLight),
              onTap: () {},
            ),
            _ProfileTile(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: LiovaColors.textLight),
              onTap: () {},
            ),

            const SizedBox(height: 32),

            // ── Sign out ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (_) => false);
                  }
                },
                icon: const Icon(Icons.logout_rounded,
                    color: LiovaColors.notGood, size: 20),
                label: const Text('Sign Out',
                    style: TextStyle(color: LiovaColors.notGood)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: LiovaColors.notGood),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Center(
              child: Text('Liova v1.0.0',
                  style: TextStyle(color: LiovaColors.textLight, fontSize: 12)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(currentIndex: 2),
      floatingActionButton: ScanFAB(
        onPressed: () => Navigator.pushNamed(context, '/scan'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: LiovaText.label.copyWith(
            color: LiovaColors.textLight, letterSpacing: 1),
      );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: LiovaDecorations.card(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: LiovaColors.rose),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: LiovaText.caption),
              const SizedBox(height: 2),
              Text(value, style: LiovaText.heading3),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: LiovaDecorations.card(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: LiovaColors.rose),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: LiovaText.heading3)),
            trailing,
          ],
        ),
      ),
    );
  }
}
