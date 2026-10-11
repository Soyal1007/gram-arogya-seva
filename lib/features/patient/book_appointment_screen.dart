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
import 'package:gram_aarogya_seva/shared/widgets/date_leaf.dart';
import 'package:gram_aarogya_seva/shared/widgets/large_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/inline_error.dart';
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
                icon: const Icon(Icons.arrow_back_rounded),
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
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepRow(currentStep: draft.step),
                  const SizedBox(height: 28),
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
        Text(tr('select_doctor'), style: AppTextStyles.headlineMedium),
        const SizedBox(height: 16),

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
              prefixIcon: const Icon(Icons.location_on_outlined),
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
                  margin: const EdgeInsets.only(bottom: 10),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    leading: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.medical_services_outlined,
                          color: AppColors.primary),
                    ),
                    title: Text(tr('doctor_name', args: [doc.name]),
                        style: AppTextStyles.titleLarge),
                    subtitle: Text(doc.specialization,
                        style: AppTextStyles.bodyMedium),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.outline, size: 28),
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
            style: AppTextStyles.headlineMedium),
        Text(doctor.specialization, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 20),

        Text(tr('select_date'), style: AppTextStyles.titleLarge),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: List.generate(8, (i) {
              final date = DateTime.now().add(Duration(days: i));
              final dateStr = AppDateUtils.toSchemaDate(date);
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _DateOption(
                  schemaDate: dateStr,
                  isToday: i == 0,
                  selected: draft.date == dateStr,
                  onTap: () => notifier.selectDate(dateStr),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 20),

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
                          const Icon(Icons.local_hospital_outlined,
                              size: 22, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(centerName,
                                style: AppTextStyles.titleMedium
                                    .copyWith(color: AppColors.primary)),
                          ),
                        ],
                      ),
                    ),
                  Text(tr('select_time_slot'), style: AppTextStyles.titleLarge),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: openSlots.map((slot) {
                      final isSelected = draft.timeSlot == slot.time;
                      return ChoiceChip(
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        label: Text(
                          AppDateUtils.formatSlotForDisplay(slot.time),
                          style: AppTextStyles.titleMedium.copyWith(
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppColors.onSurface,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.zari
                              : AppColors.outlineVariant,
                          width: isSelected ? 1.5 : 1,
                        ),
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
            icon: Icons.arrow_forward_rounded,
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
        Text(tr('appointment_details'), style: AppTextStyles.headlineMedium),
        const SizedBox(height: 16),

        // Summary of what is being booked, so the patient checks it once
        // before the form below.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.zari, width: 1.2),
          ),
          child: Row(
            children: [
              DateLeaf(schemaDate: draft.date!),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateUtils.formatSlotForDisplay(draft.timeSlot!),
                      style: AppTextStyles.titleLarge,
                    ),
                    Text(tr('doctor_name', args: [draft.doctor!.name]),
                        style: AppTextStyles.bodyLarge),
                    Text(AppDateUtils.toDisplayDate(draft.date!),
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        DropdownButtonFormField<String>(
          initialValue: draft.reason,
          decoration: InputDecoration(
            labelText: tr('reason_for_visit'),
            prefixIcon: const Icon(Icons.notes_rounded),
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
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _durationCtrl,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            labelText: tr('duration_label'),
            prefixIcon: const Icon(Icons.schedule_rounded),
          ),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: draft.severity,
          decoration: InputDecoration(
            labelText: tr('severity_label'),
            prefixIcon: const Icon(Icons.thermostat_rounded),
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
            padding: const EdgeInsets.only(bottom: 12),
            child: InlineError(message: tr('booking_requires_network')),
          ),
        LargeButton(
          label: tr('confirm_booking'),
          icon: Icons.check_circle_outline_rounded,
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
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant, width: 0.8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.outline),
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
    // Booking is a real sequence, so the steps are numbered; a finished
    // step shows a tick, the current one is filled peacock.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(labels.length, (i) {
        final isDone = i < currentStep;
        final isCurrent = i == currentStep;
        final reached = isDone || isCurrent;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i == 0
                          ? Colors.transparent
                          : (reached
                              ? AppColors.primary
                              : AppColors.outlineVariant),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent
                          ? AppColors.primary
                          : (isDone
                              ? AppColors.primaryFixed
                              : AppColors.surfaceContainerLowest),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.zari
                            : (isDone
                                ? AppColors.primary
                                : AppColors.outlineVariant),
                        width: isCurrent ? 2 : 1.2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check_rounded,
                            size: 20, color: AppColors.primary)
                        : Text(
                            '${i + 1}',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isCurrent
                                  ? AppColors.onPrimary
                                  : AppColors.outline,
                              height: 1.1,
                            ),
                          ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i == labels.length - 1
                          ? Colors.transparent
                          : (isDone
                              ? AppColors.primary
                              : AppColors.outlineVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                labels[i],
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: reached ? AppColors.primary : AppColors.outline,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// One day in the date strip: a calendar leaf that fills peacock when chosen.
class _DateOption extends StatelessWidget {
  const _DateOption({
    required this.schemaDate,
    required this.isToday,
    required this.selected,
    required this.onTap,
  });

  final String schemaDate;
  final bool isToday;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final leaf = AppDateUtils.toDateLeaf(schemaDate);
    final fg = selected ? AppColors.onPrimary : AppColors.onSurface;
    final sub = selected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 76,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.zari : AppColors.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  isToday ? tr('today') : (leaf?.weekday ?? ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(color: sub),
                ),
                Text(
                  leaf?.day ?? schemaDate,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: fg,
                    height: 1.1,
                  ),
                ),
                Text(
                  leaf?.month ?? '',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: sub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
