import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/errors/app_exception.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/shared/widgets/logout_button.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/crypto_utils.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/models/doctor_model.dart';
import 'package:gram_aarogya_seva/shared/widgets/large_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/status_badge.dart';

/// Shown while doctor awaits admin approval. Streams doctor doc for auto-navigation.
/// SRS §11.2 D-FLOW-01 Step 5: "Awaiting Approval screen (listens to doctor doc stream)"
class AwaitingApprovalScreen extends ConsumerWidget {
  const AwaitingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final doctorStream = ref.watch(_doctorStreamProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('awaiting_approval_title')),
        actions: [
          const LogoutButton(),
        ],
      ),
      body: doctorStream.when(
        data: (doctor) {
          if (doctor == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Auto-navigate on approval
          if (doctor.status == AppConstants.doctorActive) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(AppConstants.routeDoctorDashboard);
            });
            return const Center(child: CircularProgressIndicator());
          }

          // Rejected — show note + resubmit
          if (doctor.status == AppConstants.doctorRejected) {
            return _RejectedView(doctor: doctor);
          }

          // Pending approval
          return _PendingView(doctor: doctor);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(tr('error_generic'), style: AppTextStyles.bodyLarge),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(tr('retry')),
                onPressed: () => ref.invalidate(_doctorStreamProvider(user.uid)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingView extends StatelessWidget {
  final DoctorModel doctor;
  const _PendingView({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.statusPending.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              size: 64,
              color: AppColors.statusPending,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            tr('awaiting_approval_title'),
            style: AppTextStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            tr('awaiting_approval_message'),
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Registration details
          _InfoRow(label: tr('label_name'), value: doctor.name),
          _InfoRow(label: tr('label_specialisation'), value: doctor.specialization),
          _InfoRow(label: tr('label_nmr_id'), value: doctor.nmrId),
          _InfoRow(label: tr('label_hpr_id'), value: doctor.hprId),
          _InfoRow(
            label: tr('label_aadhaar'),
            value: CryptoUtils.maskedAadhaar(doctor.aadhaarLastFour),
          ),
          _InfoRow(
            label: tr('label_villages'),
            value: tr('villages_selected', args: ['${doctor.villages.length}']),
          ),
          const SizedBox(height: 16),
          const StatusBadge(status: 'pending_approval'),
        ],
      ),
    );
  }
}

/// SRS §11.2 D-FLOW-01 Step 7: Rejected — show note + "Resubmit" button
class _RejectedView extends ConsumerWidget {
  final DoctorModel doctor;
  const _RejectedView({required this.doctor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.statusRejected.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_rounded,
              size: 64,
              color: AppColors.statusRejected,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            tr('registration_rejected'),
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.statusRejected,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (doctor.rejectionNote != null && doctor.rejectionNote!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.statusRejected.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.statusRejected.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('rejection_note'),
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doctor.rejectionNote!,
                    style: AppTextStyles.bodyLarge,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          LargeButton(
            label: tr('resubmit_registration'),
            icon: Icons.refresh_rounded,
            // `status` is admin-owned in the security rules, so the doctor
            // cannot make this transition directly — the previous direct
            // write was silently denied and the doctor was stuck on this
            // screen for good (TECHNICAL_ASSESSMENT.md §11.3).
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(functionsServiceProvider)
                    .resubmitDoctorRegistration();
              } on AppException catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text(tr(e.messageKey))),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyLarge),
          ),
        ],
      ),
    );
  }
}

/// Stream provider for the doctor document.
final _doctorStreamProvider =
    StreamProvider.family<DoctorModel?, String>((ref, doctorId) {
  return ref.read(firestoreServiceProvider).streamDoctor(doctorId);
});
