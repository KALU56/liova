import 'package:flutter/material.dart';
import '../models/scan_model.dart';
import '../theme/app_theme.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final result = ModalRoute.of(context)!.settings.arguments as ScanResult;
    final suitColor = suitabilityColor(result.suitability);
    final suitBg = suitabilityBgColor(result.suitability);
    final emoji = suitabilityEmoji(result.suitability);

    return Scaffold(
      backgroundColor: LiovaColors.bg,
      appBar: AppBar(
        title: const Text('Analysis Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ── Image (if available) ────────────────────────────────────
          if (result.imageUrl != null && result.imageUrl!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(result.imageUrl!),
                  fit: BoxFit.cover,
                ),
                boxShadow: const [
                  BoxShadow(
                      color: LiovaColors.shadow,
                      blurRadius: 12,
                      offset: Offset(0, 4)),
                ],
              ),
            ),
            
          // ── Suitability hero ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [suitBg, LiovaColors.card],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: suitColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 10),
                Text(
                  result.suitability,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: suitColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'for ${result.yourSkin.isEmpty ? "your skin" : "${result.yourSkin} skin"}',
                  style: LiovaText.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Analysis card ────────────────────────────────────────────
          _InfoCard(
            icon: Icons.biotech_outlined,
            title: 'Analysis',
            child: Text(
              result.analysis.isEmpty ? 'No analysis available.' : result.analysis,
              style: LiovaText.body,
            ),
          ),
          const SizedBox(height: 12),

          // ── Ingredients card ─────────────────────────────────────────
          _InfoCard(
            icon: Icons.list_alt_rounded,
            title: 'Product Contains',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.productContains.isEmpty
                  ? [const Text('Not available', style: LiovaText.body)]
                  : result.productContains
                      .map((ing) => _IngredientChip(name: ing))
                      .toList(),
            ),
          ),
          const SizedBox(height: 12),

          // ── Suggestion card ──────────────────────────────────────────
          _InfoCard(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Suggestion',
            accentColor: LiovaColors.teal,
            child: Text(
              result.suggestion.isEmpty ? 'Patch test before regular use.' : result.suggestion,
              style: LiovaText.body,
            ),
          ),
          const SizedBox(height: 20),

          // ── Disclaimer ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: LiovaColors.rosePale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: LiovaColors.textLight, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI advice may not always be perfect. Patch test before regular use.',
                    style: TextStyle(
                        color: LiovaColors.textLight,
                        fontSize: 12,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info card ──────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
    this.accentColor = LiovaColors.rose,
  });
  final IconData icon;
  final String title;
  final Widget child;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LiovaDecorations.card(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 10),
              Text(title, style: LiovaText.heading3),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Ingredient chip ────────────────────────────────────────────────────────
class _IngredientChip extends StatelessWidget {
  const _IngredientChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: LiovaColors.rosePale,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LiovaColors.roseMid),
      ),
      child: Text(name,
          style: const TextStyle(
              fontSize: 12,
              color: LiovaColors.textMid,
              fontWeight: FontWeight.w500)),
    );
  }
}
