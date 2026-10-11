import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/providers/locale_provider.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';

/// Three-way language switch, each language written in its own script so a
/// user who cannot read English still finds theirs. One tap, no menu.
/// SRS DP-1: 3 languages from any screen.
///
/// Sits on a peacock header ([onDark] true) or on porcelain.
class LanguageSegmented extends ConsumerWidget {
  const LanguageSegmented({super.key, this.onDark = true});

  final bool onDark;

  static const _options = [
    (Locale('mr'), 'मराठी'),
    (Locale('hi'), 'हिंदी'),
    (Locale('en'), 'English'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = context.locale.languageCode;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: onDark
            ? AppColors.primaryDeep.withValues(alpha: 0.55)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: onDark
              ? AppColors.onPrimary.withValues(alpha: 0.45)
              : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (locale, label) in _options)
            Flexible(
              child: _Segment(
                label: label,
                selected: current == locale.languageCode,
                onDark: onDark,
                onTap: () async {
                  await context.setLocale(locale);
                  ref.read(appLocaleProvider.notifier).state = locale;
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool onDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedBg = onDark ? AppColors.onPrimary : AppColors.primary;
    final selectedFg = onDark ? AppColors.primaryDeep : AppColors.onPrimary;
    final idleFg = onDark ? AppColors.onPrimary : AppColors.onSurface;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? selectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 76),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: AppTextStyles.titleMedium.copyWith(
                color: selected ? selectedFg : idleFg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
