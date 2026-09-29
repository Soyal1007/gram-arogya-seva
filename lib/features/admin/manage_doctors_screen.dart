import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/models/doctor_model.dart';
import 'package:gram_aarogya_seva/shared/widgets/status_badge.dart';
import 'package:gram_aarogya_seva/shared/widgets/confirmation_dialog.dart';
import 'package:gram_aarogya_seva/features/admin/admin_providers.dart';

/// SRS §11.1 A-FLOW-01: Manage all doctors (view, activate, deactivate).
class ManageDoctorsScreen extends ConsumerWidget {
  const ManageDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(allDoctorsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('manage_doctors'))),
      body: doctorsAsync.when(
        data: (doctors) {
          if (doctors.isEmpty) {
            return Center(
              child: Text(tr('no_results'), style: AppTextStyles.titleLarge),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: doctors.length,
            itemBuilder: (_, i) {
              final doc = doctors[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doc.name,
                                    style: AppTextStyles.titleLarge),
                                Text(doc.specialization,
                                    style: AppTextStyles.bodyMedium),
                              ],
                            ),
                          ),
                          StatusBadge(status: doc.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(tr('mobile_value', args: [doc.mobile]),
                          style: AppTextStyles.caption),
                      Text(
                          tr('nmr_hpr_value',
                              args: [doc.nmrId, doc.hprId]),
                          style: AppTextStyles.caption),
                      Text(
                          tr('villages_count',
                              args: ['${doc.villages.length}']),
                          style: AppTextStyles.caption),
                      const SizedBox(height: 12),
                      // Status action button
                      // Deactivating a doctor hides them from every patient in
                      // their villages, so it gets a confirmation like every
                      // other destructive action (SRS §13.6).
                      if (doc.status == AppConstants.doctorActive)
                        OutlinedButton.icon(
                          onPressed: () => _setStatus(
                            context,
                            ref,
                            doctor: doc,
                            status: AppConstants.doctorInactive,
                            title: tr('deactivate'),
                            message:
                                tr('deactivate_confirm', args: [doc.name]),
                            confirmColor: AppColors.error,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          icon: const Icon(Icons.block, size: 18),
                          label: Text(tr('deactivate')),
                        )
                      else if (doc.status == AppConstants.doctorInactive)
                        ElevatedButton.icon(
                          onPressed: () => _setStatus(
                            context,
                            ref,
                            doctor: doc,
                            status: AppConstants.doctorActive,
                            title: tr('activate'),
                            message: tr('activate_confirm', args: [doc.name]),
                            confirmColor: AppColors.success,
                          ),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success),
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(tr('activate')),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(tr('error_generic'))),
      ),
    );
  }

  /// Confirms, then applies an activation state change.
  ///
  /// The doctor is notified by the `onDoctorStatusChanged` trigger, so the
  /// message reflects the committed write rather than this client's intent.
  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref, {
    required DoctorModel doctor,
    required String status,
    required String title,
    required String message,
    required Color confirmColor,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await ConfirmationDialog.show(
      context,
      title: title,
      message: message,
      confirmLabel: title,
      confirmColor: confirmColor,
    );
    if (confirmed != true) return;

    try {
      final adminUid = ref.read(authStateProvider).valueOrNull?.uid ?? '';
      await ref.read(firestoreServiceProvider).updateDoctorStatus(
            doctorId: doctor.doctorId,
            status: status,
            approvedBy:
                status == AppConstants.doctorActive ? adminUid : null,
          );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(tr('error_generic'))),
      );
    }
  }
}
