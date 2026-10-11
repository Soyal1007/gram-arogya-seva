import 'package:flutter/material.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';

/// Green header panel at the top of every home screen and the sign-in flow.
///
/// Deliberately plain: one solid brand colour with rounded lower corners, so
/// the page reads as "header, then content" at a glance on a small, dim
/// screen. The content inside (greeting, counters, language) is the only
/// thing that draws the eye.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: child,
    );
  }
}

/// The app mark: a medical cross in a white circle.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.onPrimary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.local_hospital_rounded,
        size: size * 0.52,
        color: AppColors.primary,
      ),
    );
  }
}
