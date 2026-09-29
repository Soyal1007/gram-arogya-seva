import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/errors/app_exception.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/models/availability_model.dart';
import 'package:gram_aarogya_seva/core/models/health_center_model.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';
import 'package:gram_aarogya_seva/shared/widgets/large_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/confirmation_dialog.dart';
import 'package:gram_aarogya_seva/features/doctor/doctor_providers.dart';

/// SRS §11.2 D-FLOW-03: Doctor sets availability per date.
/// Calendar picker → health centre dropdown → add/remove time slots → save.
class AvailabilityManagementScreen extends ConsumerStatefulWidget {
  const AvailabilityManagementScreen({super.key});

  @override
  ConsumerState<AvailabilityManagementScreen> createState() =>
      _AvailabilityManagementScreenState();
}

class _AvailabilityManagementScreenState
    extends ConsumerState<AvailabilityManagementScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<SlotModel> _slots = [];
  String? _selectedHealthCenterId;
  bool _isSaving = false;
  bool _slotsInitialized = false;

  /// Pre-defined time slots for rural schedule.
  static const List<String> _defaultTimeSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '14:00', '14:30', '15:00', '15:30', '16:00',
    '16:30', '17:00',
  ];

  @override
  Widget build(BuildContext context) {
    final dateStr = AppDateUtils.toSchemaDate(_selectedDay);
    final availAsync = ref.watch(doctorAvailabilityProvider);
    final doctorAsync = ref.watch(doctorProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('manage_availability')),
        actions: [
          // SRS A-FLOW-03 / R-15: the most likely real-world failure is that
          // the doctor cannot travel. One action cancels the day and notifies
          // every affected patient, instead of leaving them to arrive.
          IconButton(
            tooltip: tr('cancel_day'),
            icon: const Icon(Icons.event_busy_outlined),
            onPressed: _cancelDay,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 30)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                  _slots = [];
                  _selectedHealthCenterId = null;
                  _slotsInitialized = false;
                });
                ref.read(selectedDateProvider.notifier).state =
                    AppDateUtils.toSchemaDate(selected);
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: AppTextStyles.titleLarge,
              ),
            ),
            const SizedBox(height: 20),

            // Date header
            Text(
              tr('slots_for_date', args: [AppDateUtils.toDisplayDate(dateStr)]),
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 12),

            // Health Centre Dropdown — D-FLOW-02 Step 4
            doctorAsync.when(
              data: (doctor) {
                if (doctor == null) return const SizedBox.shrink();
                return _HealthCentreDropdown(
                  villageIds: doctor.villages,
                  selectedCenterId: _selectedHealthCenterId,
                  onChanged: (centerId) {
                    setState(() => _selectedHealthCenterId = centerId);
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Current availability status
            availAsync.when(
              data: (availability) {
                // Sync local state with Firestore on first load
                if (!_slotsInitialized && availability != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _slots = List.from(availability.slots);
                        _selectedHealthCenterId ??= availability.healthCenterId.isNotEmpty
                            ? availability.healthCenterId
                            : null;
                        _slotsInitialized = true;
                      });
                    }
                  });
                }

                if (availability == null) return const SizedBox.shrink();
                return Text(
                  tr('slots_configured',
                      args: ['${availability.slots.length}']),
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.success),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text(tr('error_generic')),
            ),
            const SizedBox(height: 12),

            // Time slot grid — tap to toggle
            Text(tr('select_time_slots'),
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _defaultTimeSlots.map((time) {
                final isSelected = _slots.any((s) => s.time == time);
                final isBooked = _slots
                    .where((s) => s.time == time)
                    .any((s) => s.isBooked);

                return ChoiceChip(
                  label: Text(
                    time,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isBooked
                          ? AppColors.error
                          : isSelected
                              ? AppColors.onPrimary
                              : AppColors.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor:
                      isBooked ? AppColors.error.withValues(alpha: 0.2) : AppColors.primary,
                  onSelected: isBooked
                      ? null // Can't toggle booked slots
                      : (selected) {
                          setState(() {
                            if (selected) {
                              _slots.add(SlotModel(time: time));
                            } else {
                              _slots.removeWhere((s) => s.time == time);
                            }
                          });
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              tr('slots_selected_summary', args: [
                '${_slots.length}',
                '${_slots.where((s) => s.isBooked).length}',
              ]),
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 24),

            // Save button
            LargeButton(
              label: tr('save'),
              icon: Icons.save_rounded,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveAvailability,
            ),
          ],
        ),
      ),
    );
  }

  /// Bulk-cancels every open appointment on the selected date.
  Future<void> _cancelDay() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    final dateStr = AppDateUtils.toSchemaDate(_selectedDay);
    final confirmed = await ConfirmationDialog.show(
      context,
      title: tr('cancel_day'),
      message: tr('cancel_day_confirm',
          args: [AppDateUtils.toDisplayDate(dateStr)]),
      confirmLabel: tr('cancel_day'),
      confirmColor: AppColors.error,
    );
    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final cancelled = await ref
          .read(functionsServiceProvider)
          .cancelDoctorDay(doctorId: uid, date: dateStr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('cancel_day_done', args: ['$cancelled']))),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(e.messageKey))),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  /// Saves the day's slots.
  ///
  /// The write goes to `setDoctorAvailability` rather than straight to
  /// Firestore: a whole-document `set()` from local state silently un-books
  /// any slot booked while this screen was open, and the merge that prevents
  /// that has to happen where the read and write are atomic
  /// (TECHNICAL_ASSESSMENT.md §11.9).
  Future<void> _saveAvailability() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    // SRS D-FLOW-02: the health centre is what tells the patient where to go,
    // so an availability without one is not useful to anybody.
    if (_selectedHealthCenterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('select_health_center_required'))),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(functionsServiceProvider).setAvailability(
            doctorId: uid,
            date: AppDateUtils.toSchemaDate(_selectedDay),
            healthCenterId: _selectedHealthCenterId!,
            slotTimes: _slots.map((slot) => slot.time).toList(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('availability_saved'))),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(e.messageKey))),
        );
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }
}

/// Health Centre dropdown filtered by doctor's registered villages.
/// SRS D-FLOW-02 Step 4.
class _HealthCentreDropdown extends ConsumerWidget {
  final List<String> villageIds;
  final String? selectedCenterId;
  final ValueChanged<String?> onChanged;

  const _HealthCentreDropdown({
    required this.villageIds,
    required this.selectedCenterId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stream health centres for all of the doctor's villages
    final centersAsync = ref.watch(_doctorHealthCentersProvider(villageIds));

    return centersAsync.when(
      data: (centers) {
        if (centers.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('no_health_centers'),
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          );
        }

        final validCenterId =
            (selectedCenterId != null && centers.any((c) => c.centerId == selectedCenterId))
                ? selectedCenterId
                : null;

        return DropdownButtonFormField<String>(
          initialValue: validCenterId,
          decoration: InputDecoration(
            labelText: tr('select_health_center'),
            prefixIcon: const Icon(Icons.local_hospital),
            border: const OutlineInputBorder(),
          ),
          items: centers.map((center) {
            return DropdownMenuItem(
              value: center.centerId,
              child: Text(
                center.name,
                style: AppTextStyles.bodyLarge,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => Text(tr('error_generic')),
    );
  }
}

/// Streams health centres across all of a doctor's registered villages.
final _doctorHealthCentersProvider =
    StreamProvider.family<List<HealthCenterModel>, List<String>>((ref, villageIds) {
  if (villageIds.isEmpty) return Stream.value([]);
  final firestoreService = ref.read(firestoreServiceProvider);
  // Stream all active health centres, then filter client-side by doctor's villages
  return firestoreService.streamHealthCenters().map((centers) {
    return centers.where((c) => villageIds.contains(c.villageId)).toList();
  });
});
