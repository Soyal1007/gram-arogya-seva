import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/errors/app_exception.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/providers/reference_data_providers.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';
import 'package:gram_aarogya_seva/core/providers/pagination_provider.dart';
import 'package:gram_aarogya_seva/shared/widgets/load_more_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/confirmation_dialog.dart';
import 'package:gram_aarogya_seva/shared/widgets/status_badge.dart';
import 'package:gram_aarogya_seva/features/operator/operator_providers.dart';

/// Assisted appointments — SRS §5.1 Operator module.
///
/// Everything this operator booked on someone's behalf, with the ability to
/// cancel. This matters more than it looks: the villagers an operator books
/// for are frequently the ones with no phone, so if the operator cannot
/// cancel for them, nobody can, and the slot is lost.
class OperatorAppointmentsScreen extends ConsumerWidget {
  const OperatorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync =
        ref.watch(operatorAssistedAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('assisted_appointments'))),
      body: appointmentsAsync.when(
        data: (appointments) {
          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note_outlined,
                      size: 64,
                      color: AppColors.disabled.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(tr('no_assisted_bookings'),
                      style: AppTextStyles.bodyLarge),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length + 1,
            itemBuilder: (_, i) => i == appointments.length
                ? LoadMoreButton(
                    pageKey: PageKeys.operatorAppointments,
                    loadedCount: appointments.length,
                  )
                : _AssistedAppointmentCard(appointment: appointments[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(tr('error_generic'))),
      ),
    );
  }
}

class _AssistedAppointmentCard extends ConsumerStatefulWidget {
  const _AssistedAppointmentCard({required this.appointment});

  final AppointmentModel appointment;

  @override
  ConsumerState<_AssistedAppointmentCard> createState() =>
      _AssistedAppointmentCardState();
}

class _AssistedAppointmentCardState
    extends ConsumerState<_AssistedAppointmentCard> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final apt = widget.appointment;
    final centerName = ref.watch(healthCenterNameProvider(apt.healthCenterId));

    final isOpen = apt.status == AppConstants.appointmentPending ||
        apt.status == AppConstants.appointmentAccepted;
    final canCancel = isOpen &&
        AppDateUtils.canCancel(
          date: apt.date,
          timeSlot: apt.timeSlot,
          slotStartAt: apt.slotStartAt,
        );

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
                  child: Text(
                    apt.patientName.isNotEmpty
                        ? apt.patientName
                        : tr('patient_label'),
                    style: AppTextStyles.titleLarge,
                  ),
                ),
                StatusBadge(status: apt.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${AppDateUtils.toDisplayDate(apt.date)} • '
              '${AppDateUtils.formatSlotForDisplay(apt.timeSlot)}',
              style: AppTextStyles.bodyMedium,
            ),
            if (apt.doctorName.isNotEmpty)
              Text(tr('doctor_value', args: [apt.doctorName]),
                  style: AppTextStyles.caption),
            if (centerName != null)
              Row(
                children: [
                  const Icon(Icons.local_hospital,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(centerName,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
            Text(tr('reason_label', args: [apt.reason]),
                style: AppTextStyles.caption),

            // A villager registered without a phone cannot receive any
            // notification, so the operator has to tell them in person.
            if (apt.patientUserId == null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.phonelink_erase_outlined,
                        size: 16, color: AppColors.statusPending),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(tr('no_phone_notification'),
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.statusPending)),
                    ),
                  ],
                ),
              ),

            if (isOpen) ...[
              const SizedBox(height: 8),
              if (_isCancelling)
                const Center(child: CircularProgressIndicator())
              else if (canCancel)
                OutlinedButton.icon(
                  onPressed: _cancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(0, 48),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: Text(tr('cancel_appointment')),
                )
              else
                Text(tr('cancel_too_late'),
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.error)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancel() async {
    final apt = widget.appointment;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: tr('cancel_appointment'),
      message: tr('cancel_confirm', args: [
        apt.doctorName,
        AppDateUtils.toDisplayDate(apt.date),
        AppDateUtils.formatSlotForDisplay(apt.timeSlot),
      ]),
      confirmLabel: tr('cancel_appointment'),
      confirmColor: AppColors.error,
    );
    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      // `cancelAppointment` authorises the operator who created the booking;
      // the same call refuses one they did not.
      await ref
          .read(functionsServiceProvider)
          .cancelAppointment(apt.appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('appointment_cancelled'))),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(e.messageKey))),
        );
      }
    }
    if (mounted) setState(() => _isCancelling = false);
  }
}
