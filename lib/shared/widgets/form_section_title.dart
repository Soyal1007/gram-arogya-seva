import 'package:flutter/material.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';

/// Title for a group of form fields: serif heading over a short gold rule.
/// Long forms (profile, registration) read as a few named parts instead of
/// one undivided column of boxes.
class FormSectionTitle extends StatelessWidget {
  const FormSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.zari,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}
