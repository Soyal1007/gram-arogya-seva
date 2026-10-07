import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/errors/app_exception.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/shared/widgets/logout_button.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';
import 'package:gram_aarogya_seva/core/providers/pagination_provider.dart';
import 'package:gram_aarogya_seva/shared/widgets/load_more_button.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/providers/reference_data_providers.dart';
import 'package:gram_aarogya_seva/shared/widgets/status_badge.dart';
import 'package:gram_aarogya_seva/shared/widgets/large_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/language_toggle.dart';
import 'package:gram_aarogya_seva/shared/widgets/notification_bell.dart';
import 'package:gram_aarogya_seva/shared/widgets/confirmation_dialog.dart';
import 'package:gram_aarogya_seva/shared/widgets/reschedule_dialog.dart';
import 'package:gram_aarogya_seva/features/patient/patient_providers.dart';

/// Patient home — SRS §11.3 P-FLOW-01.
class PatientDashboardScreen extends ConsumerWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(patientProfileProvider);
    final appointmentsAsync = ref.watch(myAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('dashboard')),
        actions: [
          const NotificationBell(),
          const LanguageToggle(),
          const LogoutButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(patientProfileProvider);
          ref.invalidate(myAppointmentsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profileAsync.when(
                data: (patient) => patient == null
                    ? const _NoProfileCard()
                    : _ProfileCard(
                        name: patient.name,
                        villageId: patient.villageId,
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // SRS §5.1: a profile is required before booking — the
              // appointment carries the patient's village and name.
              //
              // The button waits for the profile to resolve rather than
              // treating "still loading" as "no profile". Testing
              // `valueOrNull == null` sent a returning patient to the profile
              // editor whenever they tapped during the load window — which on
              // a rural connection is seconds long (PATIENT_MODULE.md P-02).
              LargeButton(
                label: tr('book_appointment'),
                icon: Icons.add_circle_outline,
                isLoading: profileAsync.isLoading,
                onPressed: profileAsync.isLoading
                    ? null
                    : () {
                        if (profileAsync.hasError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr('error_generic'))),
                          );
                          return;
                        }
                        if (profileAsync.value == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(tr('complete_profile_first'))),
                          );
                          context.push(AppConstants.routePatientProfile);
                          return;
                        }
                        context.push('/patient/book');
                      },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      title: tr('health_records'),
                      icon: Icons.folder_shared_rounded,
                      color: const Color(0xFF006039),
                      bgColor: const Color(0xFFE8F5E9),
                      onTap: () => context.push(AppConstants.routeHealthRecords),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      title: tr('register_as_doctor'),
                      icon: Icons.medical_services_rounded,
                      color: const Color(0xFF1B6D24),
                      bgColor: const Color(0xFFE8F5E9),
                      onTap: () {
                        ref
                            .read(isDoctorRegistrationIntentProvider.notifier)
                            .state = true;
                        context.push('/doctor/register');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(tr('my_appointments'), style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),

              appointmentsAsync.when(
                data: (appointments) {
                  if (appointments.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.event_busy,
                              size: 48,
                              color: AppColors.disabled.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(tr('no_appointments'),
                              style: AppTextStyles.bodyLarge),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      ...appointments.map(
                        (apt) => PatientAppointmentCard(appointment: apt),
                      ),
                      LoadMoreButton(
                        pageKey: PageKeys.patientAppointments,
                        loadedCount: appointments.length,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Text(tr('error_generic')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoProfileCard extends StatelessWidget {
  const _NoProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusPending.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.statusPending.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber,
              color: AppColors.statusPending, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('complete_profile_first'),
                    style: AppTextStyles.titleLarge),
                const SizedBox(height: 4),
                Text(tr('tap_create_profile'), style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => context.push(AppConstants.routePatientProfile),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.name, required this.villageId});

  final String name;
  final String villageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villageName = ref.watch(villageNameProvider(villageId));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primaryFixed,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'P',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppColors.primaryFixed),
                    const SizedBox(width: 4),
                    Text(
                      villageName ?? tr('loading'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryFixed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => context.push(AppConstants.routePatientProfile),
          ),
        ],
      ),
    );
  }
}

/// One appointment row on the patient's dashboard.
///
/// Shared with the health-records screen, replacing the near-duplicate cards
/// that had accumulated across screens (SRS §9 shared widget contract).
class PatientAppointmentCard extends ConsumerStatefulWidget {
  const PatientAppointmentCard({super.key, required this.appointment});

  final AppointmentModel appointment;

  @override
  ConsumerState<PatientAppointmentCard> createState() =>
      _PatientAppointmentCardState();
}

class _PatientAppointmentCardState
    extends ConsumerState<PatientAppointmentCard> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final apt = widget.appointment;
    final centerName = ref.watch(healthCenterNameProvider(apt.healthCenterId));

    final isOpen = apt.status == AppConstants.appointmentPending ||
        apt.status == AppConstants.appointmentAccepted;

    // An appointment the doctor never closed out stays `accepted` for ever,
    // so "open" alone does not mean "still ahead of us". Without this the
    // card told a patient they could not cancel a visit that happened last
    // week, because it was inside the 2-hour window (PATIENT_MODULE.md P-05).
    final hasPassed = AppDateUtils.hasSlotPassed(
      date: apt.date,
      timeSlot: apt.timeSlot,
      slotStartAt: apt.slotStartAt,
    );
    final canCancel = isOpen &&
        !hasPassed &&
        AppDateUtils.canCancel(
          date: apt.date,
          timeSlot: apt.timeSlot,
          slotStartAt: apt.slotStartAt,
        );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${AppDateUtils.toDisplayDate(apt.date)} • '
                    '${AppDateUtils.formatSlotForDisplay(apt.timeSlot)}',
                    style: AppTextStyles.titleLarge,
                  ),
                ),
                StatusBadge(status: apt.status),
              ],
            ),
            const SizedBox(height: 6),
            if (apt.doctorName.isNotEmpty)
              Text(tr('doctor_name', args: [apt.doctorName]),
                  style: AppTextStyles.bodyMedium),
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

            if (apt.prepInstructions?.isNotEmpty ?? false)
              _InfoBox(
                icon: Icons.info_outline,
                color: AppColors.info,
                text: apt.prepInstructions!,
              ),
            if (apt.status == AppConstants.appointmentRejected &&
                (apt.rejectionReason?.isNotEmpty ?? false))
              _InfoBox(
                icon: Icons.cancel_outlined,
                color: AppColors.error,
                text: apt.rejectionReason!,
              ),

            // Past-but-still-open appointments show no action at all: the
            // patient cannot do anything until the doctor records an outcome,
            // and saying "too late to cancel" about last week is alarming
            // rather than informative.
            if (isOpen && !hasPassed) ...[
              const SizedBox(height: 8),
              if (_isCancelling)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    if (canCancel)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _cancelAppointment,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            minimumSize: const Size(0, 48),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: Text(tr('cancel_appointment')),
                        ),
                      ),
                    if (canCancel) const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _rescheduleAppointment,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        icon: const Icon(Icons.edit_calendar, size: 18),
                        label: Text(tr('reschedule_appointment')),
                      ),
                    ),
                  ],
                ),
              if (!canCancel)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(tr('cancel_too_late'),
                      style:
                          AppTextStyles.caption.copyWith(color: AppColors.error)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancelAppointment() async {
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

  Future<void> _rescheduleAppointment() async {
    final apt = widget.appointment;
    final success = await RescheduleDialog.show(context, appointment: apt);
    if (success == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('appointment_rescheduled'))),
      );
    }
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: AppTextStyles.caption)),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
