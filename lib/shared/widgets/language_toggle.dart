import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/providers/locale_provider.dart';

/// Language toggle button for AppBar — shows current language name
/// instead of a generic globe icon. SRS DP-1: 3 languages from any screen.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = context.locale;
    final label = _localeLabel(currentLocale);

    return PopupMenuButton<Locale>(
      onSelected: (locale) async {
        await context.setLocale(locale);
        ref.read(appLocaleProvider.notifier).state = locale;
      },
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AppColors.surfaceContainerLowest,
      itemBuilder: (_) => [
        _buildItem(const Locale('en'), 'English', currentLocale),
        _buildItem(const Locale('mr'), 'मराठी', currentLocale),
        _buildItem(const Locale('hi'), 'हिंदी', currentLocale),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.onPrimary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: AppColors.onPrimary.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<Locale> _buildItem(
      Locale locale, String label, Locale current) {
    final isSelected = locale == current;
    return PopupMenuItem<Locale>(
      value: locale,
      child: Row(
        children: [
          if (isSelected)
            Icon(Icons.check_rounded,
                size: 18, color: AppColors.primary)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? AppColors.primary : AppColors.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  String _localeLabel(Locale locale) {
    switch (locale.languageCode) {
      case 'hi':
        return 'हिंदी';
      case 'mr':
        return 'मराठी';
      case 'en':
      default:
        return 'English';
    }
  }
}
