import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/shared/widgets/warli.dart';

/// Splash screen shown while Firebase + auth state loads.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.muralGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              const AppMark(size: 112),
              const SizedBox(height: 28),
              Text(
                'ग्राम आरोग्य सेवा',
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.onMural,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Gram Aarogya Seva',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.onMuralMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 48),
                child: WarliBand(height: 40),
              ),
              const Spacer(flex: 2),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppColors.zariBright,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
