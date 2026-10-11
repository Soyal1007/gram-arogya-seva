import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';

/// Modal bottom sheet presenting essential emergency healthcare contacts
/// tailored for rural villagers (108 Ambulance, 104 Health Helpline, ASHA assistance).
class EmergencyHelplineSheet extends StatelessWidget {
  const EmergencyHelplineSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EmergencyHelplineSheet(),
    );
  }

  void _copyNumber(BuildContext context, String number, String name) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name ($number) - ${tr("confirm")}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        // Kumkum edge marks this as the urgent sheet.
        border: Border(top: BorderSide(color: AppColors.error, width: 3)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('emergency_helpline'),
                        style: AppTextStyles.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('emergency_desc'),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: tr('cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 108 Ambulance — the urgent one, filled kumkum
            _buildContactCard(
              context,
              icon: Icons.airport_shuttle_rounded,
              accent: AppColors.error,
              tint: AppColors.errorContainer,
              title: tr('emergency_ambulance'),
              number: '108',
              subtitle: context.locale.languageCode == 'mr'
                  ? 'मोफत शासकीय रुग्णवाहिका सेवा (२४ तास)'
                  : context.locale.languageCode == 'hi'
                      ? 'निःशुल्क सरकारी एम्बुलेंस सेवा (24 घंटे)'
                      : 'Free Government Ambulance Service (24x7)',
            ),
            const SizedBox(height: 12),

            // 104 Health Helpline
            _buildContactCard(
              context,
              icon: Icons.phone_in_talk_rounded,
              accent: AppColors.primary,
              tint: AppColors.primaryFixed,
              title: tr('emergency_health_call'),
              number: '104',
              subtitle: context.locale.languageCode == 'mr'
                  ? 'तज्ञ डॉक्टरांचा आरोग्य व वैद्यकीय सल्ला'
                  : context.locale.languageCode == 'hi'
                      ? 'चिकित्सा व स्वास्थ्य संबंधी निःशुल्क सलाह'
                      : 'Free medical and health guidance helpline',
            ),
            const SizedBox(height: 12),

            // ASHA Worker Support
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.zariSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.volunteer_activism_rounded,
                      color: AppColors.zariDeep, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('asha_worker_support'),
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr('asha_support_desc'),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required Color tint,
    required String title,
    required String number,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleLarge),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _copyNumber(context, number, title),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: AppColors.onPrimary,
              minimumSize: const Size(88, 52),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            icon: const Icon(Icons.call_rounded, size: 20),
            label: Text(
              number,
              style: const TextStyle(
                fontFamily: AppTextStyles.sans,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
