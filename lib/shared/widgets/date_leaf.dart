import 'package:flutter/material.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';

/// Calendar leaf for an appointment row: weekday, large day number, month.
/// The date is the first thing a patient looks for, so it gets its own block
/// instead of sitting inside a sentence.
class DateLeaf extends StatelessWidget {
  const DateLeaf({super.key, required this.schemaDate, this.muted = false});

  /// `YYYY-MM-DD`.
  final String schemaDate;

  /// Past / closed appointments render in neutral tones.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final leaf = AppDateUtils.toDateLeaf(schemaDate);
    final fg = muted ? AppColors.onSurfaceVariant : AppColors.primary;
    final bg = muted ? AppColors.surfaceContainer : AppColors.primaryFixed;

    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: leaf == null
          ? Icon(Icons.event_rounded, color: fg)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  leaf.weekday,
                  style: AppTextStyles.labelMedium.copyWith(color: fg),
                ),
                Text(
                  leaf.day,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: fg,
                    height: 1.05,
                  ),
                ),
                Text(
                  leaf.month,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }
}
