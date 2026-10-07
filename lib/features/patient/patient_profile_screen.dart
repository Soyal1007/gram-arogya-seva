import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/models/patient_model.dart';
import 'package:gram_aarogya_seva/core/models/user_model.dart';
import 'package:gram_aarogya_seva/core/utils/validators.dart';
import 'package:gram_aarogya_seva/shared/widgets/large_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/profile_photo_picker.dart';
import 'package:gram_aarogya_seva/features/patient/patient_providers.dart';
import 'package:gram_aarogya_seva/shared/widgets/location_picker_widget.dart';

/// SRS §11.3 P-FLOW-01: Patient profile create/edit.
class PatientProfileScreen extends ConsumerStatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  ConsumerState<PatientProfileScreen> createState() =>
      _PatientProfileScreenState();
}

class _PatientProfileScreenState
    extends ConsumerState<PatientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emergNameCtrl = TextEditingController();
  final _emergPhoneCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  String _gender = AppConstants.genderMale;
  String? _villageId;
  String? _photoBase64;
  bool _isSaving = false;
  bool _isEdit = false;
  String? _existingPatientId;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    final patient = await ref.read(firestoreServiceProvider).getPatientByUserId(uid);
    if (patient != null && mounted) {
      setState(() {
        _isEdit = true;
        _existingPatientId = patient.patientId;
        _nameCtrl.text = patient.name;
        _dobCtrl.text = patient.dob;
        _gender = patient.gender;
        _mobileCtrl.text = patient.mobile ?? '';
        _villageId = patient.villageId;
        _photoBase64 = patient.photoBase64;
        _emergNameCtrl.text = patient.emergencyContact.name;
        _emergPhoneCtrl.text = patient.emergencyContact.phone;
        _allergiesCtrl.text = patient.medicalBackground.allergies.join(', ');
        _conditionsCtrl.text = patient.medicalBackground.conditions.join(', ');
      });
    } else if (mounted) {
      // Pre-fill mobile from auth
      final phone = ref.read(authStateProvider).valueOrNull?.phoneNumber;
      if (phone != null) {
        _mobileCtrl.text = phone.replaceAll('+91', '');
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _mobileCtrl.dispose();
    _emergNameCtrl.dispose();
    _emergPhoneCtrl.dispose();
    _allergiesCtrl.dispose();
    _conditionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reads the `reference/current` aggregate rather than streaming the whole
    // villages collection — the same read-cost fix already applied elsewhere
    // (PATIENT_MODULE.md P-11).
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? tr('edit_profile') : tr('create_profile')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo
              ProfilePhotoPicker(
                initialPhotoBase64: _photoBase64,
                onPhotoChanged: (base64) =>
                    setState(() => _photoBase64 = base64),
              ),
              const SizedBox(height: 24),

              // Name
              Text(tr('personal_details'), style: AppTextStyles.headlineSmall),
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
                    initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    _dobCtrl.text =
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  }
                },
                validator: (v) => Validators.validateRequired(v, 'Date of Birth'),
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

              // Mobile
              TextFormField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  labelText: tr('mobile_label'),
                  prefixText: '+91 ',
                  prefixIcon: const Icon(Icons.phone),
                  counterText: '',
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
              const SizedBox(height: 24),

              // Emergency Contact
              Text(tr('emergency_contact'), style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergNameCtrl,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  labelText: tr('contact_name'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergPhoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  labelText: tr('contact_phone'),
                  prefixText: '+91 ',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  counterText: '',
                ),
                validator: Validators.validateOptionalPhone,
              ),
              const SizedBox(height: 24),

              // Medical Background
              Text(tr('medical_background'), style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),
              TextFormField(
                controller: _allergiesCtrl,
                maxLines: 2,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  labelText: tr('allergies_label'),
                  prefixIcon: const Icon(Icons.warning_amber),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _conditionsCtrl,
                maxLines: 2,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  labelText: tr('conditions_label'),
                  prefixIcon: const Icon(Icons.medical_information),
                ),
              ),
              const SizedBox(height: 32),

              // Save
              LargeButton(
                label: tr('save'),
                icon: Icons.save_rounded,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Villages arrive from the reference aggregate. If it has not loaded, the
    // dropdown is not rendered, so its validator never runs and the earlier
    // bare `return` left the Save button looking broken with no explanation
    // (PATIENT_MODULE.md P-10).
    if (_villageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('select_village_error'))),
      );
      return;
    }

    setState(() => _isSaving = true);
    final uid = ref.read(authStateProvider).valueOrNull?.uid ?? '';

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      // Ensure user document exists in users/{uid}
      if (uid.isNotEmpty) {
        final existingUser = await firestoreService.getUser(uid);
        if (existingUser == null) {
          final authUser = ref.read(authStateProvider).valueOrNull;
          await firestoreService.createOrUpdateUser(
            UserModel.newPatient(
              uid: uid,
              phone: authUser?.phoneNumber?.replaceAll('+91', '') ?? _mobileCtrl.text.trim(),
            ),
          );
        }
      }
      final patient = PatientModel(
        patientId: _existingPatientId ?? '',
        userId: uid,
        name: _nameCtrl.text.trim(),
        dob: _dobCtrl.text.trim(),
        gender: _gender,
        mobile: _mobileCtrl.text.trim().isNotEmpty ? _mobileCtrl.text.trim() : null,
        villageId: _villageId!,
        photoBase64: _photoBase64,
        emergencyContact: EmergencyContact(
          name: _emergNameCtrl.text.trim(),
          phone: _emergPhoneCtrl.text.trim(),
        ),
        medicalBackground: MedicalBackground(
          allergies: _allergiesCtrl.text.trim().isNotEmpty
              ? _allergiesCtrl.text.trim().split(',')
                  .map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
              : [],
          conditions: _conditionsCtrl.text.trim().isNotEmpty
              ? _conditionsCtrl.text.trim().split(',')
                  .map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
              : [],
        ),
      );

      if (_isEdit && _existingPatientId != null) {
        await firestoreService.updatePatient(
              _existingPatientId!,
              patient.toJson(),
            );
      } else {
        await firestoreService.createPatient(patient);
      }

      ref.invalidate(patientProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('profile_saved'))),
        );
        Navigator.pop(context);
      }
    } catch (e, stack) {
      // SRS §12.1: users see a friendly message; the detail goes to logs
      // (and, once wired up, to Crashlytics) rather than onto the screen.
      debugPrint('[PatientProfile] save failed: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('error_generic'))),
        );
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }
}
