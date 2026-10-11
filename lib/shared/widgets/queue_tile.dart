import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';
import 'package:gram_aarogya_seva/shared/widgets/status_badge.dart';

/// One row of a day's queue (doctor and operator home screens). The time is
/// the left column, tinted by status, because staff scan a queue by time.
class QueueTile extends StatelessWidget {
  const QueueTile({super.key, required this.appointment, this.onTap});

  final AppointmentModel appointment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final slot = AppDateUtils.formatSlotForDisplay(appointment.timeSlot);
    final parts = slot.split(' ');
    final fg = AppColors.statusColor(appointment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.statusBgColor(appointment.status),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      parts.first,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: fg,
                        height: 1.1,
                      ),
                    ),
                    if (parts.length > 1)
                      Text(
                        parts.last,
                        style: AppTextStyles.labelMedium.copyWith(color: fg),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName.isNotEmpty
                          ? appointment.patientName
                          : tr('patient_label'),
                      style: AppTextStyles.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      appointment.reason,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(status: appointment.status),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}
