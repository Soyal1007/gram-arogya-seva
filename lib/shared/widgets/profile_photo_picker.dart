import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';

/// Profile photo picker widget — stores photo as base64 in Firestore.
/// Optional, helps identification at health centres.
class ProfilePhotoPicker extends StatefulWidget {
  final String? initialPhotoBase64;
  final ValueChanged<String?> onPhotoChanged;
  final double size;

  const ProfilePhotoPicker({
    super.key,
    this.initialPhotoBase64,
    required this.onPhotoChanged,
    this.size = 100,
  });

  @override
  State<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends State<ProfilePhotoPicker> {
  String? _photoBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _photoBase64 = widget.initialPhotoBase64;
  }

  @override
  void didUpdateWidget(ProfilePhotoPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPhotoBase64 != widget.initialPhotoBase64) {
      _photoBase64 = widget.initialPhotoBase64;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 50, // Keep small for Firestore storage
      );
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() => _photoBase64 = base64String);
        widget.onPhotoChanged(base64String);
      }
    } catch (e) {
      debugPrint('[ProfilePhoto] Error picking image: $e');
    }
  }

  void _removePhoto() {
    setState(() => _photoBase64 = null);
    widget.onPhotoChanged(null);
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tr('photo_title'), style: AppTextStyles.headlineSmall),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary),
                ),
                title: Text(tr('take_photo'), style: AppTextStyles.bodyLarge),
                subtitle: Text(tr('take_photo_hint'),
                    style: AppTextStyles.caption),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.secondary),
                ),
                title: Text(tr('choose_gallery'),
                    style: AppTextStyles.bodyLarge),
                subtitle: Text(tr('choose_gallery_hint'),
                    style: AppTextStyles.caption),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_photoBase64 != null) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_rounded,
                        color: AppColors.error),
                  ),
                  title: Text(tr('remove_photo'),
                      style: AppTextStyles.bodyLarge),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removePhoto();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _showPickerOptions,
            child: Stack(
              children: [
                // Photo circle
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainerHigh,
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    image: _photoBase64 != null
                        ? DecorationImage(
                            image: MemoryImage(base64Decode(_photoBase64!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _photoBase64 == null
                      ? Icon(
                          Icons.person_rounded,
                          size: widget.size * 0.5,
                          color: AppColors.onSurfaceVariant,
                        )
                      : null,
                ),
                // Camera badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceContainerLowest,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: widget.size * 0.18,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _photoBase64 != null ? tr('tap_to_change') : tr('add_photo_optional'),
            style: AppTextStyles.caption.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
