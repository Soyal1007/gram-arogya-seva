import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/errors/app_exception.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/validators.dart';
import 'package:gram_aarogya_seva/core/utils/crypto_utils.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/models/village_model.dart';
import 'package:gram_aarogya_seva/shared/widgets/large_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/profile_photo_picker.dart';
import 'package:gram_aarogya_seva/features/doctor_registration/doctor_reg_notifier.dart';

/// Multi-step doctor registration screen.
/// SRS §11.2 D-FLOW-01: 4-step form.
class DoctorRegistrationScreen extends ConsumerStatefulWidget {
  const DoctorRegistrationScreen({super.key});

  @override
  ConsumerState<DoctorRegistrationScreen> createState() =>
      _DoctorRegistrationScreenState();
}

class _DoctorRegistrationScreenState
    extends ConsumerState<DoctorRegistrationScreen> {
  // Step 1 controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  String _selectedSpec = DoctorRegState.specializations.first;
  String? _photoBase64;

  // Step 2 controllers
  final _nmrController = TextEditingController();
  final _hprController = TextEditingController();
  final _aadhaarController = TextEditingController();

  // Step 4 controller
  final _abdmOtpController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pre-fill mobile from auth
    final phone = ref.read(authStateProvider).valueOrNull?.phoneNumber;
    if (phone != null) {
      _mobileController.text = phone.replaceAll('+91', '');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _nmrController.dispose();
    _hprController.dispose();
    _aadhaarController.dispose();
    _abdmOtpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(doctorRegProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('register_as_doctor')),
        leading: regState.stepIndex > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => ref.read(doctorRegProvider.notifier).goBack(),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _StepIndicator(
              currentStep: regState.stepIndex,
              totalSteps: regState.totalSteps,
            ),

            // Step content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: _buildCurrentStep(regState),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(DoctorRegState state) {
    switch (state.currentStep) {
      case DoctorRegStep.basicInfo:
        return _buildBasicInfoStep(state);
      case DoctorRegStep.governmentIds:
        return _buildGovIdStep(state);
      case DoctorRegStep.villageSelection:
        return _buildVillageStep(state);
      case DoctorRegStep.abdmVerification:
        return _buildAbdmStep(state);
    }
  }

  /// Step 1: Name, Specialisation, Mobile
  Widget _buildBasicInfoStep(DoctorRegState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('step1_basic_info'), style: AppTextStyles.headlineSmall),
        const SizedBox(height: 20),
        ProfilePhotoPicker(
          initialPhotoBase64: _photoBase64,
          onPhotoChanged: (base64) =>
              setState(() => _photoBase64 = base64),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _nameController,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            labelText: tr('full_name'),
            prefixIcon: const Icon(Icons.person),
          ),
          validator: (v) => Validators.validateRequired(v, 'Name'),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedSpec,
          decoration: InputDecoration(
            labelText: tr('specialization_label'),
            prefixIcon: const Icon(Icons.medical_services),
          ),
          style: AppTextStyles.bodyLarge,
          items: DoctorRegState.specializations
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _selectedSpec = v!),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            labelText: tr('mobile_number'),
            prefixText: '+91 ',
            prefixIcon: const Icon(Icons.phone),
            counterText: '',
          ),
          validator: Validators.validatePhone,
        ),
        const SizedBox(height: 24),
        LargeButton(
          label: tr('next'),
          icon: Icons.arrow_forward,
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            ref.read(doctorRegProvider.notifier).updateBasicInfo(
                  name: _nameController.text.trim(),
                  specialization: _selectedSpec,
                  mobile: _mobileController.text.trim(),
                );
          },
        ),
      ],
    );
  }

  /// Step 2: NMR ID, HPR ID, Aadhaar
  Widget _buildGovIdStep(DoctorRegState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('step2_gov_ids'), style: AppTextStyles.headlineSmall),
        const SizedBox(height: 24),
        TextFormField(
          controller: _nmrController,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            labelText: tr('nmr_id_label'),
            prefixIcon: const Icon(Icons.badge),
          ),
          validator: Validators.validateNmrId,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _hprController,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            labelText: tr('hpr_id_label'),
            prefixIcon: const Icon(Icons.assignment_ind),
          ),
          validator: Validators.validateHprId,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _aadhaarController,
          keyboardType: TextInputType.number,
          maxLength: 12,
          obscureText: true,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            labelText: tr('aadhaar_number'),
            prefixIcon: const Icon(Icons.credit_card),
            counterText: '',
            helperText: tr('aadhaar_helper'),
          ),
          validator: Validators.validateAadhaar,
        ),
        _errorBox(state.errorMessage),
        const SizedBox(height: 24),
        LargeButton(
          label: tr('next'),
          icon: Icons.arrow_forward,
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            ref.read(doctorRegProvider.notifier).updateGovernmentIds(
                  nmrId: _nmrController.text.trim(),
                  hprId: _hprController.text.trim(),
                  aadhaarNumber: _aadhaarController.text.trim(),
                );
          },
        ),
      ],
    );
  }

  /// Step 3: Village selection (multi-select)
  Widget _buildVillageStep(DoctorRegState state) {
    final villagesAsync = ref.watch(_activeVillagesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('step3_villages'), style: AppTextStyles.headlineSmall),
        const SizedBox(height: 8),
        Text(
          tr('village_select_hint'),
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        villagesAsync.when(
          data: (villages) {
            if (villages.isEmpty) {
              return Center(
                child: Text(tr('no_villages_registered')),
              );
            }
            return Column(
              children: villages.map((village) {
                final isSelected =
                    state.selectedVillageIds.contains(village.villageId);
                return CheckboxListTile(
                  value: isSelected,
                  title: Text(village.name, style: AppTextStyles.bodyLarge),
                  subtitle: Text(
                    '${village.taluka}, ${village.district}',
                    style: AppTextStyles.caption,
                  ),
                  activeColor: AppColors.primary,
                  onChanged: (_) => ref
                      .read(doctorRegProvider.notifier)
                      .toggleVillage(village.villageId),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('${tr('error_loading_villages')}: $e'),
        ),
        _errorBox(state.errorMessage),
        const SizedBox(height: 24),
        LargeButton(
          label: tr('next'),
          icon: Icons.arrow_forward,
          onPressed: () =>
              ref.read(doctorRegProvider.notifier).confirmVillages(),
        ),
      ],
    );
  }

  /// Step 4: ABDM Aadhaar OTP verification
  Widget _buildAbdmStep(DoctorRegState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('step4_aadhaar'), style: AppTextStyles.headlineSmall),
        const SizedBox(height: 16),

        // Masked Aadhaar display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.credit_card, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                CryptoUtils.maskedAadhaar(
                  CryptoUtils.aadhaarLastFour(state.aadhaarNumber),
                ),
                style: AppTextStyles.titleLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (!state.otpSent) ...[
          // Info notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr('otp_sent_aadhaar'),
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LargeButton(
            label: tr('send_aadhaar_otp'),
            icon: Icons.send_rounded,
            isLoading: state.isLoading,
            onPressed: state.isLoading ? null : () => _sendAbdmOtp(state),
          ),
        ] else if (!state.abdmVerified) ...[
          // OTP input
          Text(
            tr('otp_sent_aadhaar'),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _abdmOtpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '------',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: Validators.validateOtp,
          ),
          const SizedBox(height: 24),
          LargeButton(
            label: tr('verify'),
            icon: Icons.verified_rounded,
            isLoading: state.isLoading,
            onPressed:
                state.isLoading ? null : () => _verifyAbdmOtp(state),
          ),
        ] else ...[
          // Verification successful — submit registration
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('aadhaar_verified'),
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LargeButton(
            label: tr('submit_registration'),
            icon: Icons.check_rounded,
            isLoading: state.isLoading,
            onPressed: state.isLoading ? null : () => _submitRegistration(state),
          ),
        ],

        _errorBox(state.errorMessage),
      ],
    );
  }

  /// Requests the Aadhaar OTP through the ABDM proxy (SRS §9.2).
  Future<void> _sendAbdmOtp(DoctorRegState state) async {
    final notifier = ref.read(doctorRegProvider.notifier);
    notifier.setLoading(true);
    try {
      final txnId = await ref
          .read(functionsServiceProvider)
          .requestAadhaarOtp(state.aadhaarNumber);
      notifier.setAbdmOtpSent(txnId);
    } on AppException catch (e) {
      notifier.setError(tr(e.messageKey));
    }
  }

  /// Verifies the Aadhaar OTP. The server records the successful verification
  /// so the submit below can require proof of it.
  Future<void> _verifyAbdmOtp(DoctorRegState state) async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(doctorRegProvider.notifier);
    notifier.setLoading(true);
    try {
      await ref.read(functionsServiceProvider).verifyAadhaarOtp(
            txnId: state.abdmTxnId!,
            otp: _abdmOtpController.text.trim(),
          );
      notifier.setAbdmVerified();
    } on AppException catch (e) {
      notifier.setError(tr(e.messageKey));
    }
  }

  /// Submits the registration.
  ///
  /// The Aadhaar number is sent once, over TLS, to be hashed with a
  /// server-held HMAC key; the doctor document and the role promotion are
  /// written together server-side. Doing either on the client would mean
  /// shipping the HMAC key in the APK and granting the client the ability to
  /// set its own role (TECHNICAL_ASSESSMENT.md §11.1, §11.7).
  ///
  /// SRS §11.2 D-FLOW-01 step 5.
  Future<void> _submitRegistration(DoctorRegState state) async {
    final notifier = ref.read(doctorRegProvider.notifier);
    notifier.setLoading(true);

    try {
      await ref.read(functionsServiceProvider).submitDoctorRegistration(
            name: state.name,
            specialization: state.specialization,
            mobile: state.mobile,
            nmrId: state.nmrId,
            hprId: state.hprId,
            aadhaarNumber: state.aadhaarNumber,
            villages: state.selectedVillageIds,
            photoBase64: _photoBase64,
          );
      notifier.setLoading(false);
      // GoRouter reacts to the role change and routes to the awaiting screen.
    } on AppException catch (e) {
      notifier.setError(tr(e.messageKey));
    }
  }

  Widget _errorBox(String? error) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(error,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step progress indicator.
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final isActive = i <= currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.disabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Provider for active villages used in Step 3.
final _activeVillagesProvider = StreamProvider<List<VillageModel>>((ref) {
  return ref.read(firestoreServiceProvider).streamActiveVillages();
});
