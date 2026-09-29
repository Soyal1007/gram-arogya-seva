import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/errors/app_exception.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/providers/connectivity_provider.dart';
import 'package:gram_aarogya_seva/core/providers/reference_data_providers.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';
import 'package:gram_aarogya_seva/shared/widgets/large_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/no_network_banner.dart';
import 'package:gram_aarogya_seva/features/patient/patient_providers.dart';

/// SRS §11.3 P-FLOW-02: booking.
///
/// Doctor → date + slot → reason and intake → confirm. The doctor list is
/// scoped to the patient's own village by default, and each slot names the
/// health centre the doctor will be at, because "where do I go" is the
/// question the whole product exists to answer.
///
/// All wizard state lives in [bookingDraftProvider], which is `autoDispose`d
/// with the screen — the free-text intake fields are the one exception, held
/// by controllers here because a `TextEditingController` is the correct owner
/// of text state and has the same lifetime.
///
/// Booking requires connectivity (DP-3): the confirm button is disabled
/// offline rather than queuing a write that cannot be validated.
class BookAppointmentScreen extends ConsumerStatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  // Controllers rather than plain fields: stepping back to the date picker and
  // forward again rebuilds the subtree, which previously left the boxes empty
  // while the captured values were still submitted (PATIENT_MODULE.md P-08).
  final _symptomsCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  bool _isBooking = false;

  @override
  void dispose() {
    _symptomsCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingDraftProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('book_appointment')),
        leading: draft.step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => ref.read(bookingDraftProvider.notifier).back(),
              )
            : null,
      ),
      body: Column(
        children: [
          Consumer(builder: (context, ref, _) {
            final isOnline =
                ref.watch(connectivityProvider).valueOrNull ?? true;
            return isOnline ? const SizedBox.shrink() : const NoNetworkBanner();
          }),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepRow(currentStep: draft.step),
                  const SizedBox(height: 20),
                  if (draft.step == 0) _buildDoctorSelection(draft),
                  if (draft.step == 1) _buildDateSlotSelection(draft),
                  if (draft.step == 2) _buildReasonAndConfirm(draft),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 0 — choose a doctor, filtered by village.
  Widget _buildDoctorSelection(BookingDraft draft) {
    final activeVillages = ref.watch(activeVillagesProvider);
    final doctorsAsync = ref.watch(bookingDoctorsProvider);
    final notifier = ref.read(bookingDraftProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('select_doctor'), style: AppTextStyles.headlineSmall),
        const SizedBox(height: 12),

        if (activeVillages.isEmpty)
          const LinearProgressIndicator()
        else
          DropdownButtonFormField<String?>(
            initialValue:
                activeVillages.any((v) => v.villageId == draft.villageId)
                    ? draft.villageId
                    : null,
            decoration: InputDecoration(
              labelText: tr('filter_by_village'),
              prefixIcon: const Icon(Icons.filter_list),
            ),
            items: [
              DropdownMenuItem(value: null, child: Text(tr('all_villages'))),
              ...activeVillages.map((v) => DropdownMenuItem(
                    value: v.villageId,
                    child: Text(v.name),
                  )),
            ],
            onChanged: notifier.selectVillage,
          ),
        const SizedBox(height: 16),

        doctorsAsync.when(
          data: (doctors) {
            if (doctors.isEmpty) {
              return _EmptyHint(
                icon: Icons.person_search,
                // SRS P-FLOW-02: say *why* the list is empty.
                message: draft.villageId != null
                    ? tr('no_doctors_in_village')
                    : tr('no_results'),
              );
            }
            return Column(
              children: doctors.map((doc) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.secondary.withValues(alpha: 0.1),
                      child: const Icon(Icons.medical_services,
                          color: AppColors.secondary),
                    ),
                    title: Text(tr('doctor_name', args: [doc.name]),
                        style: AppTextStyles.titleLarge),
                    subtitle: Text(doc.specialization,
                        style: AppTextStyles.bodyMedium),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () => notifier.selectDoctor(doc),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text(tr('error_generic')),
        ),
      ],
    );
  }

  /// Step 1 — date and slot. Includes today (a villager who walks in this
  /// morning should be able to take an afternoon slot).
  Widget _buildDateSlotSelection(BookingDraft draft) {
    final doctor = draft.doctor;
    final availAsync = ref.watch(bookingAvailabilityProvider);
    final notifier = ref.read(bookingDraftProvider.notifier);

    if (doctor == null) {
      return Center(child: Text(tr('select_doctor')));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('doctor_name', args: [doctor.name]),
            style: AppTextStyles.headlineSmall),
        Text(doctor.specialization, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 16),

        Text(tr('select_date'), style: AppTextStyles.titleLarge),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(8, (i) {
              final date = DateTime.now().add(Duration(days: i));
              final dateStr = AppDateUtils.toSchemaDate(date);
              final isSelected = draft.date == dateStr;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        i == 0
                            ? tr('today')
                            : AppDateUtils.toShortDisplayDate(dateStr),
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? AppColors.onPrimary
                              : AppColors.onSurface,
                        ),
                      ),
                      Text(
                        '${date.day}',
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
                  onSelected: (_) => notifier.selectDate(dateStr),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        if (draft.date != null)
          availAsync.when(
            data: (availability) {
              if (availability == null) {
                return _EmptyHint(
                  icon: Icons.event_busy,
                  message: tr('no_availability'),
                );
              }

              final centerName = ref
                  .watch(healthCenterNameProvider(availability.healthCenterId));

              // Same-day booking means today's earlier slots are still in the
              // document but are no longer bookable. `bookAppointment` rejects
              // them, so offering them sent the patient through the whole
              // intake form only to fail at the last step
              // (PATIENT_MODULE.md P-03).
              final openSlots = availability.slots
                  .where((s) =>
                      !s.isBooked &&
                      !AppDateUtils.hasSlotPassed(
                        date: draft.date!,
                        timeSlot: s.time,
                      ))
                  .toList();

              if (openSlots.isEmpty) {
                return _EmptyHint(
                  icon: Icons.event_busy,
                  message:
                      '${tr('all_slots_booked')}\n${tr('try_another_date')}',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The centre is shown once above the grid rather than
                  // repeated on every chip: one availability document is
                  // always a single centre for that day (SRS §7.6).
                  if (centerName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.local_hospital,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(centerName,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                  Text(tr('select_time_slot'), style: AppTextStyles.titleLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: openSlots.map((slot) {
                      final isSelected = draft.timeSlot == slot.time;
                      return ChoiceChip(
                        label: Text(
                          AppDateUtils.formatSlotForDisplay(slot.time),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppColors.onSurface,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        onSelected: (_) => notifier.selectSlot(slot.time),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(tr('error_generic')),
          ),
        const SizedBox(height: 24),

        if (draft.timeSlot != null)
          LargeButton(
            label: tr('next'),
            icon: Icons.arrow_forward,
            onPressed: () => notifier.goToStep(2),
          ),
      ],
    );
  }

  /// Step 2 — reason, intake form and confirmation.
  Widget _buildReasonAndConfirm(BookingDraft draft) {
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
    final notifier = ref.read(bookingDraftProvider.notifier);

    if (!draft.isComplete) {
      return Center(child: Text(tr('select_doctor')));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('appointment_details'), style: AppTextStyles.headlineSmall),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('doctor_name', args: [draft.doctor!.name]),
                  style: AppTextStyles.titleLarge),
              Text(
                '${AppDateUtils.toDisplayDate(draft.date!)} • '
                '${AppDateUtils.formatSlotForDisplay(draft.timeSlot!)}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          initialValue: draft.reason,
          decoration: InputDecoration(
            labelText: tr('reason_for_visit'),
            prefixIcon: const Icon(Icons.note),
          ),
          items: AppConstants.appointmentReasons
              .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(tr(AppConstants.reasonLabelKey(r))),
                  ))
              .toList(),
          onChanged: (v) => notifier.setReason(v!),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _symptomsCtrl,
          maxLines: 2,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            labelText: tr('symptoms_optional'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _durationCtrl,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            labelText: tr('duration_label'),
            prefixIcon: const Icon(Icons.schedule),
          ),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: draft.severity,
          decoration: InputDecoration(
            labelText: tr('severity_label'),
            prefixIcon: const Icon(Icons.thermostat),
          ),
          items: [
            DropdownMenuItem(
                value: AppConstants.severityMild,
                child: Text(tr('severity_mild'))),
            DropdownMenuItem(
                value: AppConstants.severityModerate,
                child: Text(tr('severity_moderate'))),
            DropdownMenuItem(
                value: AppConstants.severitySevere,
                child: Text(tr('severity_severe'))),
          ],
          onChanged: (v) => notifier.setSeverity(v!),
        ),
        const SizedBox(height: 24),

        if (!isOnline)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              tr('booking_requires_network'),
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        LargeButton(
          label: tr('confirm_booking'),
          icon: Icons.check_circle_outline,
          isLoading: _isBooking,
          onPressed: (_isBooking || !isOnline) ? null : _confirmBooking,
        ),
      ],
    );
  }

  /// Confirms the booking through `bookAppointment`.
  ///
  /// Only identifiers are sent; the server resolves the patient name, doctor
  /// name, health centre and village and performs the slot lock atomically.
  Future<void> _confirmBooking() async {
    setState(() => _isBooking = true);

    final draft = ref.read(bookingDraftProvider);
    final notifier = ref.read(bookingDraftProvider.notifier);

    try {
      final patient = await ref.read(patientProfileProvider.future);

      if (!draft.isComplete) {
        throw const InvalidOperationException('error_generic');
      }
      if (patient == null) {
        // Reaching confirm without a profile should be impossible — the
        // dashboard gates on it — but if it happens, send the patient
        // somewhere they can act rather than stranding them on step 2
        // (PATIENT_MODULE.md P-12).
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('complete_profile_first'))),
          );
          context.push(AppConstants.routePatientProfile);
        }
        return;
      }

      await ref.read(functionsServiceProvider).bookAppointment(
            doctorId: draft.doctor!.doctorId,
            patientId: patient.patientId,
            date: draft.date!,
            timeSlot: draft.timeSlot!,
            reason: draft.reason,
            intakeForm: IntakeForm(
              symptoms: _symptomsCtrl.text.trim(),
              duration: _durationCtrl.text.trim(),
              severity: draft.severity,
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('appointment_booked'))),
        );
        // The draft is disposed with the screen, so there is nothing to reset.
        Navigator.pop(context);
      }
    } on SlotAlreadyBookedException {
      // SRS §12.2: tell the user, then send them back to pick again. The live
      // availability stream will already have dropped the taken slot.
      notifier.slotTaken();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('slot_already_booked'))),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(e.messageKey))),
        );
      }
    }

    if (mounted) setState(() => _isBooking = false);
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.disabled.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.disabled),
          const SizedBox(height: 12),
          Text(message,
              style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final labels = [
      tr('step_doctor'),
      tr('step_date_slot'),
      tr('step_confirm'),
    ];
    return Row(
      children: List.generate(labels.length, (i) {
        final isActive = i <= currentStep;
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.disabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[i],
                style: AppTextStyles.caption.copyWith(
                  color: isActive ? AppColors.primary : AppColors.disabled,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
