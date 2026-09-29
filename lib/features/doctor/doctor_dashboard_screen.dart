import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/shared/widgets/logout_button.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';
import 'package:gram_aarogya_seva/shared/widgets/status_badge.dart';
import 'package:gram_aarogya_seva/shared/widgets/language_toggle.dart';
import 'package:gram_aarogya_seva/shared/widgets/notification_bell.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/features/doctor/doctor_providers.dart';

/// Doctor Dashboard — SRS §11.2 D-FLOW-02.
/// Shows today's queue, quick stats, and navigation.
class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(doctorProfileProvider);
    final appointmentsAsync = ref.watch(doctorTodayAppointmentsProvider);

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
          ref.invalidate(doctorProfileProvider);
          ref.invalidate(doctorTodayAppointmentsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              profileAsync.when(
                data: (doctor) {
                  if (doctor == null) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('welcome_doctor', args: [doctor.name]),
                        style: AppTextStyles.headlineSmall,
                      ),
                      Text(doctor.specialization,
                          style: AppTextStyles.bodyMedium),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Quick action cards — 4 navigation buttons per blueprint
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  _ActionCard(
                    icon: Icons.calendar_month,
                    label: tr('manage_availability'),
                    color: AppColors.primary,
                    onTap: () => context.push('/doctor/availability'),
                  ),
                  _ActionCard(
                    icon: Icons.list_alt,
                    label: tr('view_appointments'),
                    color: AppColors.secondary,
                    onTap: () {
                      ref.read(doctorAppointmentFilterProvider.notifier).state = null;
                      context.push('/doctor/appointments');
                    },
                    // Show pending badge count
                    badge: appointmentsAsync.whenOrNull(
                      data: (appts) {
                        final pending = appts
                            .where((a) =>
                                a.status == AppConstants.appointmentPending)
                            .length;
                        return pending > 0 ? pending : null;
                      },
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.history,
                    label: tr('appointment_history'),
                    color: AppColors.info,
                    onTap: () {
                      ref.read(doctorAppointmentFilterProvider.notifier).state =
                          AppConstants.appointmentCompleted;
                      context.push('/doctor/appointments');
                    },
                  ),
                  _ActionCard(
                    icon: Icons.person,
                    label: tr('doctor_profile'),
                    color: AppColors.success,
                    onTap: () => context.push('/doctor/profile'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Today's appointments
              Text(
                tr('todays_queue',
                    args: [
                      AppDateUtils.toDisplayDate(
                          AppDateUtils.todaySchemaDate())
                    ]),
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: 12),

              appointmentsAsync.when(
                data: (todayAppts) {
                  if (todayAppts.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.event_available, size: 48,
                              color: AppColors.disabled.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(tr('no_appointments_today'),
                              style: AppTextStyles.bodyLarge),
                        ],
                      ),
                    );
                  }

                  // Stats row
                  final pending = todayAppts
                      .where((a) => a.status == AppConstants.appointmentPending)
                      .length;
                  final accepted = todayAppts
                      .where((a) => a.status == AppConstants.appointmentAccepted)
                      .length;
                  final completed = todayAppts
                      .where((a) => a.status == AppConstants.appointmentCompleted)
                      .length;

                  return Column(
                    children: [
                      // Mini stats
                      Row(
                        children: [
                          _MiniStat(
                              tr('pending_label'), '$pending', AppColors.statusPending),
                          const SizedBox(width: 8),
                          _MiniStat(
                              tr('accepted_label'), '$accepted', AppColors.statusAccepted),
                          const SizedBox(width: 8),
                          _MiniStat(
                              tr('done_label'), '$completed', AppColors.statusCompleted),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Appointment list
                      ...todayAppts.map((apt) => _AppointmentTile(appointment: apt)),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(tr('error_generic')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int? badge;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, size: 30, color: color),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (badge != null)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTextStyles.headlineMedium.copyWith(color: color)),
            Text(label, style: AppTextStyles.caption.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _AppointmentTile extends ConsumerWidget {
  final AppointmentModel appointment;
  const _AppointmentTile({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.statusColor(appointment.status)
              .withValues(alpha: 0.15),
          child: Text(
            AppDateUtils.formatSlotForDisplay(appointment.timeSlot)
              .split(':')
              .first,
            style: TextStyle(
              color: AppColors.statusColor(appointment.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          appointment.patientName.isNotEmpty
              ? appointment.patientName
              : tr('patient_label'),
          style: AppTextStyles.titleLarge,
        ),
        subtitle: Text(
            '${AppDateUtils.formatSlotForDisplay(appointment.timeSlot)}'
            ' • ${appointment.reason}',
            style: AppTextStyles.caption),
        trailing: StatusBadge(status: appointment.status),
      ),
    );
  }
}
