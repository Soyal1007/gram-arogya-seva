import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/errors/app_exception.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/core/models/availability_model.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';

final rescheduleAvailabilityProvider =
    StreamProvider.autoDispose.family<AvailabilityModel?, ({String doctorId, String date})>((ref, arg) {
  return ref
      .watch(firestoreServiceProvider)
      .streamAvailability(arg.doctorId, arg.date);
});

class RescheduleDialog extends ConsumerStatefulWidget {
  const RescheduleDialog({super.key, required this.appointment});

  final AppointmentModel appointment;

  static Future<bool?> show(BuildContext context, {required AppointmentModel appointment}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => RescheduleDialog(appointment: appointment),
    );
  }

  @override
  ConsumerState<RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends ConsumerState<RescheduleDialog> {
  late DateTime _selectedDate;
  String? _selectedSlot;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final parsed = DateTime.tryParse(widget.appointment.date);
    _selectedDate = parsed != null && parsed.isAfter(DateTime.now())
        ? parsed
        : DateTime.now().add(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = AppDateUtils.toSchemaDate(_selectedDate);
    final availAsync = ref.watch(rescheduleAvailabilityProvider((
      doctorId: widget.appointment.doctorId,
      date: dateStr,
    )));

    return AlertDialog(
      title: Text(tr('reschedule_appointment'), style: AppTextStyles.headlineSmall),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('select_date'), style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      AppDateUtils.toDisplayDate(dateStr),
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(tr('select_time_slot'), style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            availAsync.when(
              data: (avail) {
                if (avail == null || avail.slots.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(tr('no_availability'), style: AppTextStyles.caption),
                  );
                }

                final freeSlots = avail.slots
                    .where((s) => s.isBooked != true)
                    .map((s) => s.time)
                    .toList();

                if (freeSlots.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(tr('all_slots_booked'), style: AppTextStyles.caption),
                  );
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: freeSlots.map((slot) {
                    final isSelected = _selectedSlot == slot;
                    return ChoiceChip(
                      label: Text(AppDateUtils.formatSlotForDisplay(slot)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedSlot = selected ? slot : null;
                        });
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Text(tr('error_generic'), style: AppTextStyles.caption),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: Text(tr('cancel')),
        ),
        ElevatedButton(
          onPressed: _selectedSlot == null || _isSubmitting ? null : _submitReschedule,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(tr('confirm_reschedule')),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(Duration(days: AppConstants.maxBookingDaysAhead)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
    }
  }

  Future<void> _submitReschedule() async {
    if (_selectedSlot == null) return;

    setState(() => _isSubmitting = true);
    final dateStr = AppDateUtils.toSchemaDate(_selectedDate);

    try {
      await ref.read(functionsServiceProvider).rescheduleAppointment(
            appointmentId: widget.appointment.appointmentId,
            newDate: dateStr,
            newTimeSlot: _selectedSlot!,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(e.messageKey))),
        );
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('error_generic'))),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }
}
