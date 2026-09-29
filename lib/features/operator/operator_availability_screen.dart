import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/errors/app_exception.dart';
import 'package:gram_aarogya_seva/core/models/availability_model.dart';
import 'package:gram_aarogya_seva/core/models/health_center_model.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';
import 'package:gram_aarogya_seva/shared/widgets/large_button.dart';
import 'package:gram_aarogya_seva/features/operator/operator_providers.dart';

/// Operator availability fallback — SRS §5.1 Operator, O-FLOW-04.
///
/// Doctors travel; phones run out of charge; a doctor who cannot open the app
/// still needs their slots published or nobody in the village can book. The
/// operator at the health centre is the fallback.
///
/// The same `setDoctorAvailability` function serves the doctor and the
/// operator. It authorises the caller by role and refuses a health centre
/// outside the doctor's registered villages, so the operator cannot publish a
/// doctor into a village they do not serve.
class OperatorAvailabilityScreen extends ConsumerStatefulWidget {
  const OperatorAvailabilityScreen({super.key});

  @override
  ConsumerState<OperatorAvailabilityScreen> createState() =>
      _OperatorAvailabilityScreenState();
}

class _OperatorAvailabilityScreenState
    extends ConsumerState<OperatorAvailabilityScreen> {
  /// Same rural schedule the doctor's own screen offers.
  static const List<String> _defaultTimeSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '14:00', '14:30', '15:00', '15:30', '16:00',
    '16:30', '17:00',
  ];

  final Set<String> _selected = {};
  String? _healthCenterId;
  bool _isSaving = false;
  String? _loadedKey;

  @override
  Widget build(BuildContext context) {
    final doctor = ref.watch(opAvailabilityDoctorProvider);
    final date = ref.watch(opAvailabilityDateProvider);
    final doctorsAsync = ref.watch(opBookingDoctorsProvider);
    final availabilityAsync = ref.watch(opAvailabilityProvider);

    // Load existing slots once per doctor+date, so the operator edits the
    // real schedule rather than replacing it blind.
    final key = '${doctor?.doctorId}_$date';
    availabilityAsync.whenData((availability) {
      if (_loadedKey == key) return;
      _loadedKey = key;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selected
            ..clear()
            ..addAll(availability?.slots.map((s) => s.time) ?? const []);
          _healthCenterId = availability?.healthCenterId.isNotEmpty == true
              ? availability!.healthCenterId
              : null;
        });
      });
    });

    return Scaffold(
      appBar: AppBar(title: Text(tr('manage_availability'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('availability_fallback_hint'),
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),

            // Doctor
            doctorsAsync.when(
              data: (doctors) => DropdownButtonFormField<String>(
                initialValue: doctor?.doctorId,
                decoration: InputDecoration(
                  labelText: tr('select_doctor'),
                  prefixIcon: const Icon(Icons.medical_services),
                ),
                items: doctors
                    .map((d) => DropdownMenuItem(
                          value: d.doctorId,
                          child: Text(tr('doctor_name', args: [d.name])),
                        ))
                    .toList(),
                onChanged: (id) {
                  final selected =
                      doctors.where((d) => d.doctorId == id).firstOrNull;
                  ref.read(opAvailabilityDoctorProvider.notifier).state =
                      selected;
                  setState(() {
                    _loadedKey = null;
                    _selected.clear();
                    _healthCenterId = null;
                  });
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(tr('error_generic')),
            ),
            const SizedBox(height: 16),

            // Date — the next 14 days is the practical planning horizon
            Text(tr('select_date'), style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(14, (i) {
                  final day = DateTime.now().add(Duration(days: i));
                  final dayStr = AppDateUtils.toSchemaDate(day);
                  final isSelected = date == dayStr;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            i == 0
                                ? tr('today')
                                : AppDateUtils.toShortDisplayDate(dayStr),
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? AppColors.onPrimary
                                  : AppColors.onSurface,
                            ),
                          ),
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.onPrimary
                                  : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      onSelected: (_) {
                        ref.read(opAvailabilityDateProvider.notifier).state =
                            dayStr;
                        setState(() => _loadedKey = null);
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            if (doctor == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(tr('select_doctor'),
                    style: AppTextStyles.bodyLarge),
              )
            else ...[
              _HealthCentrePicker(
                villageIds: doctor.villages,
                selectedCenterId: _healthCenterId,
                onChanged: (id) => setState(() => _healthCenterId = id),
              ),
              const SizedBox(height: 16),

              Text(tr('select_time_slots'), style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              availabilityAsync.when(
                data: (availability) => _SlotGrid(
                  allSlots: _defaultTimeSlots,
                  selected: _selected,
                  booked: {
                    for (final slot in availability?.slots ?? <SlotModel>[])
                      if (slot.isBooked) slot.time,
                  },
                  onToggle: (time, isOn) => setState(() {
                    if (isOn) {
                      _selected.add(time);
                    } else {
                      _selected.remove(time);
                    }
                  }),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => Text(tr('error_generic')),
              ),
              const SizedBox(height: 24),

              LargeButton(
                label: tr('save'),
                icon: Icons.save_rounded,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final doctor = ref.read(opAvailabilityDoctorProvider);
    if (doctor == null) return;

    if (_healthCenterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('select_health_center_required'))),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(functionsServiceProvider).setAvailability(
            doctorId: doctor.doctorId,
            date: ref.read(opAvailabilityDateProvider),
            healthCenterId: _healthCenterId!,
            slotTimes: _selected.toList(),
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

/// Slot chips. Booked slots are locked — an operator must never be able to
/// remove a slot a villager is already holding.
class _SlotGrid extends StatelessWidget {
  const _SlotGrid({
    required this.allSlots,
    required this.selected,
    required this.booked,
    required this.onToggle,
  });

  final List<String> allSlots;
  final Set<String> selected;
  final Set<String> booked;
  final void Function(String time, bool isOn) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allSlots.map((time) {
        final isBooked = booked.contains(time);
        final isSelected = selected.contains(time) || isBooked;
        return ChoiceChip(
          label: Text(
            AppDateUtils.formatSlotForDisplay(time),
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
          selectedColor: isBooked
              ? AppColors.error.withValues(alpha: 0.2)
              : AppColors.primary,
          onSelected: isBooked ? null : (isOn) => onToggle(time, isOn),
        );
      }).toList(),
    );
  }
}

/// Health centres in the selected doctor's registered villages.
class _HealthCentrePicker extends ConsumerWidget {
  const _HealthCentrePicker({
    required this.villageIds,
    required this.selectedCenterId,
    required this.onChanged,
  });

  final List<String> villageIds;
  final String? selectedCenterId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centersAsync = ref.watch(_centersForVillagesProvider(villageIds));

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
                  child: Text(tr('no_health_centers'),
                      style: AppTextStyles.caption),
                ),
              ],
            ),
          );
        }

        final valid = centers.any((c) => c.centerId == selectedCenterId)
            ? selectedCenterId
            : null;

        return DropdownButtonFormField<String>(
          initialValue: valid,
          decoration: InputDecoration(
            labelText: tr('select_health_center'),
            prefixIcon: const Icon(Icons.local_hospital),
          ),
          items: centers
              .map((c) => DropdownMenuItem(
                    value: c.centerId,
                    child: Text(c.name, style: AppTextStyles.bodyLarge),
                  ))
              .toList(),
          onChanged: onChanged,
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => Text(tr('error_generic')),
    );
  }
}

final _centersForVillagesProvider =
    StreamProvider.family<List<HealthCenterModel>, List<String>>(
        (ref, villageIds) {
  if (villageIds.isEmpty) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).streamHealthCenters().map(
        (centers) =>
            centers.where((c) => villageIds.contains(c.villageId)).toList(),
      );
});
