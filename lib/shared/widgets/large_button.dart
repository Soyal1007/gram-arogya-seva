import 'package:flutter/material.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';

/// Primary action button — Design System §5 LargeButton.
/// 60dp height, full-width, gradient fill, icon + text, fully rounded.
/// SRS §9 shared widget contract.
class LargeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool useGradient;

  const LargeButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = isLoading || onPressed == null;
    final bgColor = backgroundColor ?? AppColors.primary;
    final fgColor = foregroundColor ?? AppColors.onPrimary;

    return SizedBox(
      width: double.infinity,
      height: 60, // Premium 60dp per Design System §5
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDisabled
              ? null
              : (useGradient && backgroundColor == null)
                  ? AppColors.healingGradient
                  : null,
          color: isDisabled
              ? AppColors.outlineVariant
              : (useGradient && backgroundColor == null)
                  ? null
                  : bgColor,
          borderRadius: BorderRadius.circular(30),
          // Ambient shadow tinted with brand green (Design System §4)
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fgColor,
                    ),
                  )
                else
                  Icon(icon, size: 24, color: fgColor),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(color: fgColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
