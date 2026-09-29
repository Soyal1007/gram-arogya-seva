import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/errors/app_exception.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/providers/reference_data_providers.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';
import 'package:gram_aarogya_seva/core/providers/pagination_provider.dart';
import 'package:gram_aarogya_seva/shared/widgets/load_more_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/status_badge.dart';
import 'package:gram_aarogya_seva/shared/widgets/confirmation_dialog.dart';
import 'package:gram_aarogya_seva/features/doctor/doctor_providers.dart';

/// SRS §11.2 D-FLOW-02/03: the doctor's appointment queue.
/// Accept with prep instructions, reject with a reason, then record the
/// outcome once the appointment time has passed.
class DoctorAppointmentsScreen extends ConsumerWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(doctorAppointmentFilterProvider);
    final appointmentsAsync = ref.watch(doctorFilteredAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('view_appointments'))),
      body: Column(
        children: [
          // Status filter chips — all six statuses (SRS §7.7).
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _FilterChip(
                  label: tr('all_filter'),
                  isSelected: statusFilter == null,
                  onTap: () => ref
                      .read(doctorAppointmentFilterProvider.notifier)
                      .state = null,
                ),
                for (final status in AppConstants.allAppointmentStatuses) ...[
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: tr(AppConstants.statusLabelKey(status)),
                    isSelected: statusFilter == status,
                    onTap: () => ref
                        .read(doctorAppointmentFilterProvider.notifier)
                        .state = status,
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: appointmentsAsync.when(
              data: (appointments) {
                if (appointments.isEmpty) {
                  return Center(
                    child:
                        Text(tr('no_results'), style: AppTextStyles.titleLarge),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: appointments.length + 1,
                  itemBuilder: (_, i) => i == appointments.length
                      ? LoadMoreButton(
                          pageKey: PageKeys.doctorAppointments,
                          loadedCount: appointments.length,
                        )
                      : _DoctorAppointmentCard(appointment: appointments[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(tr('error_generic'))),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorAppointmentCard extends ConsumerStatefulWidget {
  const _DoctorAppointmentCard({required this.appointment});

  final AppointmentModel appointment;

  @override
  ConsumerState<_DoctorAppointmentCard> createState() =>
      _DoctorAppointmentCardState();
}

class _DoctorAppointmentCardState
    extends ConsumerState<_DoctorAppointmentCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final apt = widget.appointment;
    final centerName =
        ref.watch(healthCenterNameProvider(apt.healthCenterId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        apt.patientName.isNotEmpty
                            ? apt.patientName
                            : tr('patient_label'),
                        style: AppTextStyles.titleLarge,
                      ),
                      Text(
                        '${AppDateUtils.toDisplayDate(apt.date)} • '
                        '${AppDateUtils.formatSlotForDisplay(apt.timeSlot)}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: apt.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(tr('reason_label', args: [apt.reason]),
                style: AppTextStyles.bodyMedium),
            if (apt.createdByOperatorId != null)
              Text(tr('booked_by_operator'),
                  style: AppTextStyles.caption.copyWith(color: AppColors.info)),

            // Naming the centre is the point of storing it — the id alone
            // tells the doctor nothing about where they are expected to be.
            if (centerName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.local_hospital,
                        size: 14,
                        color: AppColors.primary.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(centerName,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),

            if (apt.intakeForm.symptoms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${tr('symptoms_optional')}: ${apt.intakeForm.symptoms}',
                  style: AppTextStyles.caption,
                ),
              ),

            if (apt.status == AppConstants.appointmentAccepted &&
                (apt.prepInstructions?.isNotEmpty ?? false))
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${tr('prep_instructions')}: ${apt.prepInstructions}',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildActions(apt),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(AppointmentModel apt) {
    switch (apt.status) {
      case AppConstants.appointmentPending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _rejectAppointment(apt),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size(0, 48),
                ),
                icon: const Icon(Icons.close, size: 18),
                label: Text(tr('reject')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _acceptAppointment(apt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size(0, 48),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: Text(tr('accept')),
              ),
            ),
          ],
        );

      case AppConstants.appointmentAccepted:
        // SRS D-FLOW-03: an outcome may only be recorded once the appointment
        // time has passed. The server enforces the same rule — hiding the
        // buttons early only avoids an error the doctor cannot act on.
        final hasPassed = AppDateUtils.hasSlotPassed(
          date: apt.date,
          timeSlot: apt.timeSlot,
          slotStartAt: apt.slotStartAt,
        );
        if (!hasPassed) {
          return Text(tr('outcome_after_appointment_time'),
              style: AppTextStyles.caption);
        }
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _markNoShow(apt),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusNoShow,
                  side: const BorderSide(color: AppColors.statusNoShow),
                  minimumSize: const Size(0, 48),
                ),
                icon: const Icon(Icons.person_off, size: 18),
                label: Text(tr('no_show')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _markCompleted(apt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusCompleted,
                  minimumSize: const Size(0, 48),
                ),
                icon: const Icon(Icons.done_all, size: 18),
                label: Text(tr('completed')),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  /// Runs a status transition and reports what actually happened.
  Future<void> _transition({
    required AppointmentModel apt,
    required String status,
    String? prepInstructions,
    String? rejectionReason,
    VisitSummary? visitSummary,
  }) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(functionsServiceProvider).updateAppointmentStatus(
            appointmentId: apt.appointmentId,
            status: status,
            prepInstructions: prepInstructions,
            rejectionReason: rejectionReason,
            visitSummary: visitSummary,
          );
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(e.messageKey))),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _acceptAppointment(AppointmentModel apt) async {
    final prepCtrl = TextEditingController();
    final confirmed = await ConfirmationDialog.show(
      context,
      title: tr('accept'),
      message: tr('accept_confirm', args: [apt.patientName]),
      confirmLabel: tr('accept'),
      extraContent: TextField(
        controller: prepCtrl,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: tr('prep_instructions'),
          border: const OutlineInputBorder(),
        ),
      ),
    );
    if (confirmed != true) return;

    await _transition(
      apt: apt,
      status: AppConstants.appointmentAccepted,
      prepInstructions:
          prepCtrl.text.trim().isNotEmpty ? prepCtrl.text.trim() : null,
    );
  }

  /// SRS D-FLOW-03: rejection requires a reason and frees the slot.
  Future<void> _rejectAppointment(AppointmentModel apt) async {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await ConfirmationDialog.show(
      context,
      title: tr('reject'),
      message: tr('reject_confirm', args: [apt.patientName]),
      confirmLabel: tr('reject'),
      confirmColor: AppColors.error,
      canConfirm: () => formKey.currentState?.validate() ?? false,
      extraContent: Form(
        key: formKey,
        child: TextFormField(
          controller: reasonCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: tr('rejection_reason'),
            border: const OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? tr('rejection_reason_required')
              : null,
        ),
      ),
    );
    if (confirmed != true) return;

    await _transition(
      apt: apt,
      status: AppConstants.appointmentRejected,
      rejectionReason: reasonCtrl.text.trim(),
    );
  }

  /// Marks the visit complete, optionally recording the visit summary that
  /// becomes the patient's health record (SRS §5.1 Patient — Health Records).
  Future<void> _markCompleted(AppointmentModel apt) async {
    final notesCtrl = TextEditingController();
    final prescriptionCtrl = TextEditingController();
    final nextStepsCtrl = TextEditingController();

    final confirmed = await ConfirmationDialog.show(
      context,
      title: tr('completed'),
      message: tr('complete_confirm', args: [apt.patientName]),
      confirmLabel: tr('completed'),
      confirmColor: AppColors.statusCompleted,
      extraContent: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: notesCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: tr('notes_label'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: prescriptionCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: tr('prescription_label'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nextStepsCtrl,
            decoration: InputDecoration(
              labelText: tr('next_steps_label'),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final hasSummary = notesCtrl.text.trim().isNotEmpty ||
        prescriptionCtrl.text.trim().isNotEmpty ||
        nextStepsCtrl.text.trim().isNotEmpty;

    await _transition(
      apt: apt,
      status: AppConstants.appointmentCompleted,
      visitSummary: hasSummary
          ? VisitSummary(
              notes: notesCtrl.text.trim(),
              prescription: prescriptionCtrl.text.trim(),
              nextSteps: nextStepsCtrl.text.trim(),
            )
          : null,
    );
  }

  Future<void> _markNoShow(AppointmentModel apt) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: tr('mark_no_show'),
      message: tr('mark_no_show_confirm', args: [apt.patientName]),
      confirmColor: AppColors.statusNoShow,
    );
    if (confirmed != true) return;
    await _transition(apt: apt, status: AppConstants.appointmentNoShow);
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (_) => onTap(),
    );
  }
}
