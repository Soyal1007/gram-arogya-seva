import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/models/patient_model.dart';
import 'package:gram_aarogya_seva/core/utils/validators.dart';
import 'package:gram_aarogya_seva/shared/widgets/large_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/profile_photo_picker.dart';
import 'package:gram_aarogya_seva/core/providers/reference_data_providers.dart';
import 'package:gram_aarogya_seva/shared/widgets/location_picker_widget.dart';

/// SRS §11.5 O-FLOW-02: Operator registers walk-in patient.
/// Checks for duplicate by mobile. No phone auth needed.
class OperatorRegisterPatientScreen extends ConsumerStatefulWidget {
  const OperatorRegisterPatientScreen({super.key});

  @override
  ConsumerState<OperatorRegisterPatientScreen> createState() =>
      _OperatorRegisterPatientScreenState();
}

class _OperatorRegisterPatientScreenState
    extends ConsumerState<OperatorRegisterPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  String _gender = AppConstants.genderMale;
  String? _villageId;
  String? _photoBase64;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reference aggregate rather than the whole villages collection — the
    // operator screen shared the patient profile screen's defect
    // (PATIENT_MODULE.md P-11).
    final villages = ref.watch(activeVillagesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('register_patient'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfilePhotoPicker(
                initialPhotoBase64: _photoBase64,
                onPhotoChanged: (base64) =>
                    setState(() => _photoBase64 = base64),
              ),
              const SizedBox(height: 24),
              Text(tr('patient_details'), style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameCtrl,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  labelText: tr('full_name'),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (v) => Validators.validateRequired(v, 'Name'),
              ),
              const SizedBox(height: 12),

              // DOB
              TextFormField(
                controller: _dobCtrl,
                style: AppTextStyles.bodyLarge,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: tr('dob_label'),
                  prefixIcon: const Icon(Icons.cake),
                  hintText: 'YYYY-MM-DD',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now()
                        .subtract(const Duration(days: 365 * 25)),
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    _dobCtrl.text =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  }
                },
                validator: (v) =>
                    Validators.validateRequired(v, 'Date of Birth'),
              ),
              const SizedBox(height: 12),

              // Gender
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: InputDecoration(
                  labelText: tr('gender_label'),
                  prefixIcon: const Icon(Icons.wc),
                ),
                items: AppConstants.genders
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(tr(AppConstants.genderLabelKey(g))),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v!),
              ),
              const SizedBox(height: 12),

              // Mobile (optional for walk-ins)
              TextFormField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  labelText: tr('mobile_optional'),
                  prefixText: '+91 ',
                  prefixIcon: const Icon(Icons.phone),
                  counterText: '',
                  helperText: tr('walkin_no_phone_hint'),
                ),
                validator: Validators.validateOptionalPhone,
              ),
              const SizedBox(height: 12),

              // Location Selection (District -> Taluka -> Village)
              Text(tr('location_details'), style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),
              LocationPickerWidget(
                initialVillageId: _villageId,
                showHealthCenter: false,
                villageValidator: (v) => v == null ? tr('select_village_error') : null,
                onVillageSelected: (vModel) {
                  setState(() => _villageId = vModel?.villageId);
                },
              ),
              const SizedBox(height: 32),

              // Save
              LargeButton(
                label: tr('save'),
                icon: Icons.person_add,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _registerPatient,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registerPatient() async {
    if (!_formKey.currentState!.validate()) return;
    if (_villageId == null) return;

    setState(() => _isSaving = true);

    try {
      final operatorUid =
          ref.read(authStateProvider).valueOrNull?.uid ?? '';
      final mobile = _mobileCtrl.text.trim();

      // Check for duplicate by mobile
      if (mobile.isNotEmpty) {
        final existing =
            await ref.read(firestoreServiceProvider).findPatientByMobile(mobile);
        if (existing != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('duplicate_mobile_found')),
            ),
          );
          setState(() => _isSaving = false);
          return;
        }
      }

      final patient = PatientModel(
        patientId: '',
        name: _nameCtrl.text.trim(),
        dob: _dobCtrl.text.trim(),
        gender: _gender,
        villageId: _villageId!,
        mobile: mobile.isNotEmpty ? mobile : null,
        photoBase64: _photoBase64,
        createdBy: AppConstants.createdByHealthCenter,
        createdByOperatorId: operatorUid,
      );

      await ref.read(firestoreServiceProvider).createPatient(patient);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('patient_registered'))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('error_generic'))),
        );
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }
}
