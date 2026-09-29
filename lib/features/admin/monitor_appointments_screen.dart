import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';
import 'package:gram_aarogya_seva/core/providers/pagination_provider.dart';
import 'package:gram_aarogya_seva/shared/widgets/load_more_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/status_badge.dart';
import 'package:gram_aarogya_seva/features/admin/admin_providers.dart';

/// SRS §11.1 A-FLOW-01: Monitor all appointments with status filter.
class MonitorAppointmentsScreen extends ConsumerWidget {
  const MonitorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(appointmentStatusFilterProvider);
    final appointmentsAsync = ref.watch(allAppointmentsProvider(statusFilter));

    return Scaffold(
      appBar: AppBar(title: Text(tr('monitor_appointments'))),
      body: Column(
        children: [
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _FilterChip(
                  label: tr('all_filter'),
                  isSelected: statusFilter == null,
                  onTap: () => ref
                      .read(appointmentStatusFilterProvider.notifier)
                      .state = null,
                ),
                const SizedBox(width: 8),
                ...AppConstants.allAppointmentStatuses.map((status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: tr(AppConstants.statusLabelKey(status)),
                        isSelected: statusFilter == status,
                        onTap: () => ref
                            .read(appointmentStatusFilterProvider.notifier)
                            .state = status,
                      ),
                    )),
              ],
            ),
          ),

          // Appointments list
          Expanded(
            child: appointmentsAsync.when(
              data: (appointments) {
                if (appointments.isEmpty) {
                  return Center(
                    child: Text(tr('no_results'),
                        style: AppTextStyles.titleLarge),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: appointments.length + 1,
                  itemBuilder: (_, i) {
                    if (i == appointments.length) {
                      return LoadMoreButton(
                        pageKey: PageKeys.adminAppointments,
                        loadedCount: appointments.length,
                      );
                    }
                    final apt = appointments[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
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
                            const SizedBox(height: 6),
                            Text(
                              '${AppDateUtils.toDisplayDate(apt.date)} • '
                              '${AppDateUtils.formatSlotForDisplay(apt.timeSlot)}',
                              style: AppTextStyles.bodyMedium,
                            ),
                            Text(tr('reason_label', args: [apt.reason]),
                                style: AppTextStyles.caption),
                            if (apt.doctorName.isNotEmpty)
                              Text(
                                  tr('doctor_value',
                                      args: [apt.doctorName]),
                                  style: AppTextStyles.caption),
                            if (apt.createdByOperatorId != null)
                              Text(tr('booked_by_operator'),
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.info)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text(tr('error_generic'))),
            ),
          ),
        ],
      ),
    );
  }

}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
            fontSize: 16,
            color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
          )),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (_) => onTap(),
    );
  }
}
