import 'package:flutter/material.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';

/// Navigation tile for the doctor / operator / admin home screens: icon in a
/// tinted circle, label at full body size, optional count of items that need
/// attention (pending requests, approvals).
class DashboardTile extends StatelessWidget {
  const DashboardTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = AppColors.primary,
    this.tint = AppColors.primaryFixed,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accent;
  final Color tint;

  /// Items waiting on this user. Hidden when null or zero.
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final hasBadge = badge != null && badge! > 0;

    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 128),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasBadge ? AppColors.zari : AppColors.outlineVariant,
              width: hasBadge ? 1.4 : 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    // Warli geometry: the circle (sun, head) holds the icon.
                    decoration: BoxDecoration(
                      color: tint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent, size: 26),
                  ),
                  const Spacer(),
                  if (hasBadge)
                    Container(
                      constraints: const BoxConstraints(minWidth: 32),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.zariBright,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badge',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.geruDeep,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: AppTextStyles.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays tiles out two per row with equal heights per row.
class DashboardTileGrid extends StatelessWidget {
  const DashboardTileGrid({super.key, required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: tiles[i]),
            const SizedBox(width: 12),
            Expanded(
              child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox(),
            ),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

/// Today-at-a-glance counters on the mural header, divided by rice-white rules.
class HeaderStats extends StatelessWidget {
  const HeaderStats({super.key, required this.stats});

  /// (label, value) pairs.
  final List<(String, String)> stats;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < stats.length; i++) {
      if (i > 0) {
        children.add(Container(
          width: 1,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: AppColors.onMural.withValues(alpha: 0.4),
        ));
      }
      final (label, value) = stats[i];
      children.add(Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.onMural,
                height: 1.1,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.onMuralMuted,
              ),
            ),
          ],
        ),
      ));
    }
    return Row(children: children);
  }
}
