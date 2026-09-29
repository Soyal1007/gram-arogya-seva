import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/utils/crypto_utils.dart';
import 'package:gram_aarogya_seva/shared/widgets/large_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/status_badge.dart';
import 'package:gram_aarogya_seva/features/doctor/doctor_providers.dart';

/// Doctor Profile Screen — SRS §5.1: "Profile: view/edit non-credential fields."
/// Credential fields (NMR, HPR, Aadhaar) are read-only.
class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() =>
      _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  String? _selectedSpec;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _initialized = false;

  /// Newly picked image file (not yet saved).
  File? _pickedImageFile;

  /// Base64 of a newly picked image (set when user picks from gallery).
  String? _newPhotoBase64;

  /// Set to true when the user taps "Remove Profile Pic" — tells save to clear the field.
  bool _removePhoto = false;

  static const List<String> _specializations = [
    'General Physician',
    'Gynecologist',
    'Gynaecologist',
    'Pediatrician',
    'Paediatrician',
    'Dermatologist',
    'Orthopedic',
    'Orthopaedic',
    'ENT Specialist',
    'ENT',
    'Ophthalmologist',
    'Dentist',
    'Ayurveda',
    'Homeopathy',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  // PHOTO HELPERS
  // ─────────────────────────────────────────────────────

  /// Opens the gallery and encodes the picked image to base64.
  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;

      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);

      setState(() {
        _pickedImageFile = file;
        _newPhotoBase64 = base64Str;
        _removePhoto = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('error_generic'))),
        );
      }
    }
  }

  /// Shows the bottom drawer with photo options.
  void _showPhotoOptions({
    required String? savedBase64,
  }) {
    // Determine the currently effective photo (picked > saved)
    final hasPhoto = _pickedImageFile != null ||
        (savedBase64 != null && savedBase64.isNotEmpty && !_removePhoto);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // View Profile Pic (only if there is a photo)
                if (hasPhoto)
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.visibility,
                          color: AppColors.primary),
                    ),
                    title: Text(tr('view_photo')),
                    onTap: () {
                      Navigator.pop(ctx);
                      _viewProfilePic(savedBase64: savedBase64);
                    },
                  ),

                // Change Profile Pic (only in edit mode)
                if (_isEditing)
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.photo_library,
                          color: Colors.blue),
                    ),
                    title: Text(tr('change_photo')),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickProfileImage();
                    },
                  ),

                // Remove Profile Pic (only if there is a photo AND in edit mode)
                if (_isEditing && hasPhoto)
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.red),
                    ),
                    title: Text(tr('remove_photo')),
                    titleTextStyle:
                        AppTextStyles.bodyLarge.copyWith(color: Colors.red),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _pickedImageFile = null;
                        _newPhotoBase64 = null;
                        _removePhoto = true;
                      });
                    },
                  ),

                // If not editing and no photo, show a hint
                if (!_isEditing && !hasPhoto)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No profile picture set. Tap Edit to add one.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.outline),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Opens a full-screen viewer for the current profile picture.
  void _viewProfilePic({required String? savedBase64}) {
    // Effective image provider
    ImageProvider? imageProvider;
    if (_pickedImageFile != null) {
      imageProvider = FileImage(_pickedImageFile!);
    } else if (savedBase64 != null &&
        savedBase64.isNotEmpty &&
        !_removePhoto) {
      imageProvider = MemoryImage(base64Decode(savedBase64));
    }

    if (imageProvider == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Full-screen image with pinch-to-zoom
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: SizedBox(
                width: MediaQuery.of(ctx).size.width,
                height: MediaQuery.of(ctx).size.height,
                child: Image(
                  image: imageProvider!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(doctorProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('doctor_profile')),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: tr('edit_profile'),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: doctorAsync.when(
        data: (doctor) {
          if (doctor == null) {
            return Center(child: Text(tr('error_generic')));
          }

          // Initialize form controllers once
          if (!_initialized) {
            _nameController.text = doctor.name;
            _mobileController.text = doctor.mobile;
            _selectedSpec = doctor.specialization;
            _initialized = true;
          }

          final specList = List<String>.from(_specializations);
          if (_selectedSpec != null &&
              _selectedSpec!.isNotEmpty &&
              !specList.contains(_selectedSpec)) {
            specList.add(_selectedSpec!);
          }

          // Determine avatar display: picked file > saved base64 > default icon
          ImageProvider? backgroundImage;

          if (_pickedImageFile != null) {
            backgroundImage = FileImage(_pickedImageFile!);
          } else if (!_removePhoto &&
              doctor.photoBase64 != null &&
              doctor.photoBase64!.isNotEmpty) {
            backgroundImage =
                MemoryImage(base64Decode(doctor.photoBase64!));
          }

          Widget avatarChild = backgroundImage == null
              ? const Icon(Icons.person, size: 50, color: AppColors.primary)
              : const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile header ─────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: backgroundImage,
                              child: avatarChild,
                            ),
                            // Camera button — only visible in edit mode
                            if (_isEditing)
                              GestureDetector(
                                onTap: () => _showPhotoOptions(
                                  savedBase64: doctor.photoBase64,
                                ),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        StatusBadge(status: doctor.status),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Editable: Name ─────────────────────────────
                  TextFormField(
                    controller: _nameController,
                    enabled: _isEditing,
                    style: AppTextStyles.bodyLarge,
                    decoration: InputDecoration(
                      labelText: tr('full_name'),
                      prefixIcon: const Icon(Icons.person),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? tr('full_name') : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Editable: Specialization ───────────────────
                  if (_isEditing)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSpec,
                      decoration: InputDecoration(
                        labelText: tr('specialization_label'),
                        prefixIcon: const Icon(Icons.medical_services),
                        border: const OutlineInputBorder(),
                      ),
                      style: AppTextStyles.bodyLarge,
                      items: specList
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSpec = v),
                    )
                  else
                    TextFormField(
                      initialValue: _selectedSpec ?? '',
                      enabled: false,
                      style: AppTextStyles.bodyLarge,
                      decoration: InputDecoration(
                        labelText: tr('specialization_label'),
                        prefixIcon: const Icon(Icons.medical_services),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ── Editable: Mobile ───────────────────────────
                  TextFormField(
                    controller: _mobileController,
                    enabled: _isEditing,
                    style: AppTextStyles.bodyLarge,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: tr('mobile_number'),
                      prefixIcon: const Icon(Icons.phone),
                      prefixText: '+91 ',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Read-only credential section ───────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock_outline,
                                size: 18, color: AppColors.outline),
                            const SizedBox(width: 8),
                            Text(
                              tr('credential_readonly'),
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.outline),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _ReadOnlyField(
                          label: tr('nmr_id_short'),
                          value: doctor.nmrId,
                          icon: Icons.badge,
                        ),
                        const SizedBox(height: 12),
                        _ReadOnlyField(
                          label: tr('hpr_id_short'),
                          value: doctor.hprId,
                          icon: Icons.assignment_ind,
                        ),
                        const SizedBox(height: 12),
                        _ReadOnlyField(
                          label: tr('aadhaar_label'),
                          value: CryptoUtils.maskedAadhaar(
                              doctor.aadhaarLastFour),
                          icon: Icons.credit_card,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Registered Villages ────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              tr('registered_villages'),
                              style: AppTextStyles.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: doctor.villages.map((villageId) {
                            return Chip(
                              label: Text(
                                villageId,
                                style: AppTextStyles.caption,
                              ),
                              backgroundColor: AppColors.primary
                                  .withValues(alpha: 0.08),
                            );
                          }).toList(),
                        ),
                        if (doctor.villages.isEmpty)
                          Text(tr('no_results'),
                              style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Save/Cancel buttons (edit mode only) ───────
                  if (_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _pickedImageFile = null;
                                _newPhotoBase64 = null;
                                _removePhoto = false;
                                _nameController.text = doctor.name;
                                _mobileController.text = doctor.mobile;
                                _selectedSpec = doctor.specialization;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 56),
                            ),
                            child: Text(tr('cancel')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LargeButton(
                            label: tr('save'),
                            icon: Icons.save,
                            isLoading: _isSaving,
                            onPressed:
                                _isSaving ? null : () => _saveProfile(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(tr('error_generic'))),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // SAVE
  // ─────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      // If user removed the photo, send an empty string to clear the field.
      // If user picked a new one, send the new base64.
      // If neither, send null (no change).
      final String? photoToSave =
          _removePhoto ? '' : _newPhotoBase64;

      await firestoreService.updateDoctorProfile(
        doctorId: uid,
        name: _nameController.text.trim(),
        specialization: _selectedSpec ?? '',
        mobile: _mobileController.text.trim(),
        photoBase64: photoToSave,
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
          _pickedImageFile = null;
          _newPhotoBase64 = null;
          _removePhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('profile_updated'))),
        );
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

// ─────────────────────────────────────────────────────
// READ-ONLY FIELD WIDGET
// ─────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.outline),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.outline)),
            Text(value, style: AppTextStyles.bodyLarge),
          ],
        ),
      ],
    );
  }
}
