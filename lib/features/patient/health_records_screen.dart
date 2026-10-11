import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/core/providers/pagination_provider.dart';
import 'package:gram_aarogya_seva/core/providers/reference_data_providers.dart';
import 'package:gram_aarogya_seva/shared/widgets/date_leaf.dart';
import 'package:gram_aarogya_seva/shared/widgets/empty_state.dart';
import 'package:gram_aarogya_seva/shared/widgets/load_more_button.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';
import 'package:gram_aarogya_seva/features/patient/patient_providers.dart';

/// Health Records — SRS §5.1 Patient module.
///
/// A record is a completed appointment carrying the visit summary the doctor
/// wrote when closing it out. Nothing is stored separately: the appointment
/// *is* the record, which keeps the clinical note attached to the visit it
/// describes and needs no additional collection or security surface.
class HealthRecordsScreen extends ConsumerWidget {
  const HealthRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(healthRecordsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('health_records'))),
      body: recordsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return EmptyState(
              icon: Icons.folder_open_outlined,
              message: tr('no_health_records'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length + 1,
            itemBuilder: (_, i) => i == records.length
                ? LoadMoreButton(
                    pageKey: PageKeys.patientRecords,
                    loadedCount: records.length,
                  )
                : _RecordCard(appointment: records[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => EmptyState(
          icon: Icons.cloud_off_rounded,
          message: tr('error_generic'),
        ),
      ),
    );
  }
}

class _RecordCard extends ConsumerWidget {
  const _RecordCard({required this.appointment});

  final AppointmentModel appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = appointment.visitSummary!;
    final centerName =
        ref.watch(healthCenterNameProvider(appointment.healthCenterId));

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DateLeaf(schemaDate: appointment.date),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (appointment.doctorName.isNotEmpty)
                        Text(tr('doctor_name', args: [appointment.doctorName]),
                            style: AppTextStyles.titleLarge),
                      if (centerName != null)
                        Text(centerName, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            // The prescription is what the patient comes back to read, so it
            // sits first and on its own gold-edged panel.
            if (summary.prescription.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.zariSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: const Border(
                    left: BorderSide(color: AppColors.zari, width: 4),
                  ),
                ),
                child: _Field(
                  label: tr('prescription_label'),
                  value: summary.prescription,
                  icon: Icons.medication_outlined,
                ),
              ),
            if (summary.notes.isNotEmpty)
              _Field(label: tr('notes_label'), value: summary.notes),
            if (summary.nextSteps.isNotEmpty)
              _Field(label: tr('next_steps_label'), value: summary.nextSteps),
            if (summary.followUpDate != null)
              _Field(
                label: tr('follow_up_date'),
                value: AppDateUtils.toDisplayDate(summary.followUpDate!),
              ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.zariDeep),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: icon != null
                      ? AppColors.zariDeep
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }
}
