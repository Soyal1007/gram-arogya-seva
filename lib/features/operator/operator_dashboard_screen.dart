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
import 'package:gram_aarogya_seva/features/operator/operator_providers.dart';

/// Operator Dashboard — SRS §11.5 O-FLOW-01.
/// Shows today's bookings and quick actions.
class OperatorDashboardScreen extends ConsumerWidget {
  const OperatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(operatorTodayBookingsProvider);

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
        onRefresh: () async =>
            ref.invalidate(operatorTodayBookingsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick actions — the four operator flows (SRS §5.1)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _ActionCard(
                    icon: Icons.person_add,
                    label: tr('register_patient'),
                    color: AppColors.primary,
                    onTap: () => context.push('/operator/register-patient'),
                  ),
                  _ActionCard(
                    icon: Icons.calendar_month,
                    label: tr('book_appointment'),
                    color: AppColors.secondary,
                    onTap: () => context.push('/operator/book'),
                  ),
                  _ActionCard(
                    icon: Icons.event_note,
                    label: tr('assisted_appointments'),
                    color: AppColors.info,
                    onTap: () => context.push('/operator/appointments'),
                  ),
                  _ActionCard(
                    icon: Icons.schedule,
                    label: tr('manage_availability'),
                    color: AppColors.success,
                    onTap: () => context.push('/operator/availability'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Today's bookings
              Text(
                tr('todays_bookings', args: [
                  AppDateUtils.toDisplayDate(AppDateUtils.todaySchemaDate())
                ]),
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: 12),

              bookingsAsync.when(
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.event_busy, size: 48,
                              color: AppColors.disabled.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(tr('no_bookings_today'),
                              style: AppTextStyles.bodyLarge),
                        ],
                      ),
                    );
                  }

                  // Stats
                  final pending = bookings
                      .where((a) => a.status == AppConstants.appointmentPending)
                      .length;
                  final accepted = bookings
                      .where((a) => a.status == AppConstants.appointmentAccepted)
                      .length;

                  return Column(
                    children: [
                      Row(
                        children: [
                          _MiniStat(tr('total_label'), '${bookings.length}',
                              AppColors.primary),
                          const SizedBox(width: 8),
                          _MiniStat(tr('pending_label'), '$pending',
                              AppColors.statusPending),
                          const SizedBox(width: 8),
                          _MiniStat(tr('accepted_label'), '$accepted',
                              AppColors.statusAccepted),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...bookings.map((apt) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.statusColor(apt.status)
                                    .withValues(alpha: 0.15),
                                child: Text(
                                  AppDateUtils.formatSlotForDisplay(
                                          apt.timeSlot)
                                      .split(':')
                                      .first,
                                  style: TextStyle(
                                    color: AppColors.statusColor(apt.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                apt.patientName.isNotEmpty
                                    ? apt.patientName
                                    : tr('patient_label'),
                                style: AppTextStyles.titleLarge,
                              ),
                              subtitle: Text(
                                '${AppDateUtils.formatSlotForDisplay(apt.timeSlot)}'
                                ' • ${apt.reason}',
                                style: AppTextStyles.caption,
                              ),
                              trailing: StatusBadge(status: apt.status),
                            ),
                          )),
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
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

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(label,
                  style: AppTextStyles.bodyMedium.copyWith(color: color),
                  textAlign: TextAlign.center),
            ],
          ),
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
