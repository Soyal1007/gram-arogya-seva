import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/core/providers/pagination_provider.dart';
import 'package:gram_aarogya_seva/core/providers/reference_data_providers.dart';
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open_outlined,
                        size: 64,
                        color: AppColors.disabled.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(tr('no_health_records'),
                        style: AppTextStyles.bodyLarge,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
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
        error: (_, __) => Center(child: Text(tr('error_generic'))),
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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppDateUtils.toDisplayDate(appointment.date),
                style: AppTextStyles.titleLarge),
            if (appointment.doctorName.isNotEmpty)
              Text(tr('doctor_name', args: [appointment.doctorName]),
                  style: AppTextStyles.bodyMedium),
            if (centerName != null)
              Text(centerName,
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.primary)),
            const Divider(height: 24),
            if (summary.notes.isNotEmpty)
              _Field(label: tr('notes_label'), value: summary.notes),
            if (summary.prescription.isNotEmpty)
              _Field(
                  label: tr('prescription_label'),
                  value: summary.prescription),
            if (summary.nextSteps.isNotEmpty)
              _Field(label: tr('next_steps_label'), value: summary.nextSteps),
            if (summary.followUpDate != null) ...[
              _Field(
                label: tr('follow_up_date'),
                value: AppDateUtils.toDisplayDate(summary.followUpDate!),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.go('/patient/book');
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(tr('book_followup')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }
}
