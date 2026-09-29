import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/errors/app_exception.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/models/appointment_model.dart';
import 'package:gram_aarogya_seva/core/models/patient_model.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';
import 'package:gram_aarogya_seva/core/utils/validators.dart';
import 'package:gram_aarogya_seva/shared/widgets/large_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/no_network_banner.dart';
import 'package:gram_aarogya_seva/core/providers/connectivity_provider.dart';
import 'package:gram_aarogya_seva/features/operator/operator_providers.dart';

/// SRS §11.5 O-FLOW-03: Operator books appointment on behalf of patient.
/// Search patient by mobile → select doctor → date/slot → confirm.
class OperatorBookAppointmentScreen extends ConsumerStatefulWidget {
  const OperatorBookAppointmentScreen({super.key});

  @override
  ConsumerState<OperatorBookAppointmentScreen> createState() =>
      _OperatorBookAppointmentScreenState();
}

class _OperatorBookAppointmentScreenState
    extends ConsumerState<OperatorBookAppointmentScreen> {
  int _step = 0; // 0=patient, 1=doctor, 2=date+slot, 3=confirm
  final _mobileCtrl = TextEditingController();
  PatientModel? _patient;
  bool _isSearching = false;
  String _selectedReason = AppConstants.appointmentReasons.first;
  bool _isBooking = false;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('book_appointment')),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step--),
              )
            : null,
      ),
      body: Column(
        children: [
          // SRS DP-3: Show offline banner when no connectivity
          Consumer(builder: (context, ref, _) {
            final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
            return isOnline ? const SizedBox.shrink() : const NoNetworkBanner();
          }),
          Expanded(
            child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            _StepRow(currentStep: _step),
            const SizedBox(height: 20),
            if (_step == 0) _buildPatientSearch(),
            if (_step == 1) _buildDoctorSelection(),
            if (_step == 2) _buildDateSlotSelection(),
            if (_step == 3) _buildConfirm(),
          ],
        ),
      ),
          ),
        ],
      ),
    );
  }

  /// Step 0: Search patient by mobile
  Widget _buildPatientSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('find_patient'), style: AppTextStyles.headlineSmall),
        const SizedBox(height: 16),
        TextFormField(
          controller: _mobileCtrl,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            labelText: tr('patient_mobile_number'),
            prefixText: '+91 ',
            prefixIcon: const Icon(Icons.phone),
            counterText: '',
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _searchPatient,
            ),
          ),
          validator: Validators.validatePhone,
          onFieldSubmitted: (_) => _searchPatient(),
        ),
        const SizedBox(height: 12),

        if (_isSearching)
          const Center(child: CircularProgressIndicator())
        else if (_patient != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_patient!.name, style: AppTextStyles.titleLarge),
                      Text(
                        '${_patient!.gender} • DOB: ${_patient!.dob}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: AppColors.success),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LargeButton(
            label: tr('next'),
            icon: Icons.arrow_forward,
            onPressed: () => setState(() => _step = 1),
          ),
        ],
      ],
    );
  }

  Future<void> _searchPatient() async {
    final mobile = _mobileCtrl.text.trim();
    if (mobile.length != 10) return;

    setState(() {
      _isSearching = true;
      _patient = null;
    });

    try {
      final result =
          await ref.read(firestoreServiceProvider).findPatientByMobile(mobile);
      if (mounted) {
        setState(() {
          _patient = result;
          _isSearching = false;
        });
        if (result == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('patient_not_found')),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('error_generic'))),
        );
      }
    }
  }

  /// Step 1: Select doctor
  Widget _buildDoctorSelection() {
    final doctorsAsync = ref.watch(opBookingDoctorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('select_doctor'), style: AppTextStyles.headlineSmall),
        const SizedBox(height: 12),
        doctorsAsync.when(
          data: (doctors) {
            if (doctors.isEmpty) {
              return Text(tr('no_results'), style: AppTextStyles.bodyLarge);
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
                    trailing:
                        const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      ref.read(opBookingDoctorProvider.notifier).state = doc;
                      setState(() => _step = 2);
                    },
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

  /// Step 2: Date + slot
  Widget _buildDateSlotSelection() {
    final doctor = ref.watch(opBookingDoctorProvider);
    final selectedDate = ref.watch(opBookingDateProvider);
    final availAsync = ref.watch(opBookingAvailabilityProvider);
    final selectedSlot = ref.watch(opBookingSlotProvider);

    if (doctor == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('doctor_name', args: [doctor.name]),
            style: AppTextStyles.headlineSmall),
        const SizedBox(height: 16),

        // Date chips
        Text(tr('select_date'), style: AppTextStyles.titleLarge),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(7, (i) {
              final date = DateTime.now().add(Duration(days: i));
              final dateStr = AppDateUtils.toSchemaDate(date);
              final isSelected = selectedDate == dateStr;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                            [date.weekday - 1],
                        style: TextStyle(
                          fontSize: 14,
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
                  onSelected: (_) {
                    ref.read(opBookingDateProvider.notifier).state = dateStr;
                    ref.read(opBookingSlotProvider.notifier).state = null;
                  },
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // Slots
        if (selectedDate != null)
          availAsync.when(
            data: (availability) {
              if (availability == null) {
                return Text(tr('no_availability'),
                    style: AppTextStyles.bodyLarge);
              }
              final openSlots =
                  availability.slots.where((s) => !s.isBooked).toList();
              if (openSlots.isEmpty) {
                return Text(tr('all_slots_booked'),
                    style: AppTextStyles.bodyLarge);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('select_time_slot'),
                      style: AppTextStyles.titleLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: openSlots.map((slot) {
                      final isSelected = selectedSlot == slot.time;
                      return ChoiceChip(
                        label: Text(
                          slot.time,
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
                        onSelected: (_) => ref
                            .read(opBookingSlotProvider.notifier)
                            .state = slot.time,
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

        if (selectedSlot != null)
          LargeButton(
            label: tr('next'),
            icon: Icons.arrow_forward,
            onPressed: () => setState(() => _step = 3),
          ),
      ],
    );
  }

  /// Step 3: Reason and confirm
  Widget _buildConfirm() {
    final doctor = ref.watch(opBookingDoctorProvider);
    final date = ref.watch(opBookingDateProvider);
    final slot = ref.watch(opBookingSlotProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('appointment_details'), style: AppTextStyles.headlineSmall),
        const SizedBox(height: 16),

        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('patient_value', args: [_patient?.name ?? '']),
                  style: AppTextStyles.titleLarge),
              Text(tr('doctor_value', args: [doctor?.name ?? '']),
                  style: AppTextStyles.bodyMedium),
              Text(
                '${AppDateUtils.toDisplayDate(date!)} at $slot',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Reason
        DropdownButtonFormField<String>(
          initialValue: _selectedReason,
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
          onChanged: (v) => setState(() => _selectedReason = v!),
        ),
        const SizedBox(height: 24),

        // Confirm — disabled when offline (SRS DP-3)
        Builder(builder: (context) {
          final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;
          return Column(
            children: [
              if (!isOnline)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Internet required to book appointment',
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
        }),
      ],
    );
  }

  /// Books on the patient's behalf (SRS O-FLOW-02).
  ///
  /// The same `bookAppointment` function serves patients and operators; it
  /// reads the caller's role and stamps `createdBy: 'health_center'` plus
  /// `createdByOperatorId` itself, so an operator booking cannot be
  /// misattributed and a patient cannot claim to be one.
  Future<void> _confirmBooking() async {
    setState(() => _isBooking = true);

    try {
      final doctor = ref.read(opBookingDoctorProvider);
      final date = ref.read(opBookingDateProvider);
      final slot = ref.read(opBookingSlotProvider);

      if (doctor == null || date == null || slot == null || _patient == null) {
        throw const InvalidOperationException('error_generic');
      }

      await ref.read(functionsServiceProvider).bookAppointment(
            doctorId: doctor.doctorId,
            patientId: _patient!.patientId,
            date: date,
            timeSlot: slot,
            reason: _selectedReason,
            intakeForm: IntakeForm(severity: AppConstants.severityMild),
          );

      ref.read(opBookingDoctorProvider.notifier).state = null;
      ref.read(opBookingDateProvider.notifier).state = null;
      ref.read(opBookingSlotProvider.notifier).state = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('appointment_booked'))),
        );
        Navigator.pop(context);
      }
    } on SlotAlreadyBookedException {
      ref.invalidate(opBookingAvailabilityProvider);
      ref.read(opBookingSlotProvider.notifier).state = null;
      if (mounted) {
        setState(() => _step = 2);
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

class _StepRow extends StatelessWidget {
  final int currentStep;
  const _StepRow({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final labels = [
      tr('step_patient'),
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
              Text(labels[i],
                  style: AppTextStyles.caption.copyWith(
                    color: isActive ? AppColors.primary : AppColors.disabled,
                    fontSize: 12,
                  )),
            ],
          ),
        );
      }),
    );
  }
}
