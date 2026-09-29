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

/// SRS §11.1 A-FLOW-01 Step 3: Approve/Reject doctors.
class PendingApprovalsScreen extends ConsumerWidget {
  const PendingApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingDoctorsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('pending_approvals'))),
      body: pendingAsync.when(
        data: (doctors) {
          if (doctors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: AppColors.success.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(tr('no_pending_approvals'),
                      style: AppTextStyles.titleLarge),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: doctors.length,
            itemBuilder: (context, index) =>
                _DoctorApprovalCard(doctor: doctors[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(tr('error_generic'))),
      ),
    );
  }
}

class _DoctorApprovalCard extends ConsumerStatefulWidget {
  final DoctorModel doctor;
  const _DoctorApprovalCard({required this.doctor});

  @override
  ConsumerState<_DoctorApprovalCard> createState() =>
      _DoctorApprovalCardState();
}

class _DoctorApprovalCardState extends ConsumerState<_DoctorApprovalCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor.name, style: AppTextStyles.titleLarge),
                      Text(doctor.specialization,
                          style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
                const StatusBadge(status: 'pending_approval'),
              ],
            ),
            const Divider(height: 24),

            // Details
            _DetailRow(tr('mobile_label'), doctor.mobile),
            _DetailRow(tr('nmr_id_short'), doctor.nmrId),
            _DetailRow(tr('hpr_id_short'), doctor.hprId),
            _DetailRow(tr('aadhaar_label'),
                'XXXX XXXX ${doctor.aadhaarLastFour}'),
            _DetailRow(tr('villages_label'),
                tr('villages_selected', args: ['${doctor.villages.length}'])),
            if (doctor.abdmTxnId != null)
              _DetailRow('ABDM', tr('aadhaar_verified')),
            const SizedBox(height: 16),

            // Action buttons
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(doctor),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(0, 52),
                      ),
                      icon: const Icon(Icons.close),
                      label: Text(tr('reject')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveDoctor(doctor),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(0, 52),
                      ),
                      icon: const Icon(Icons.check),
                      label: Text(tr('approve')),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// SRS A-FLOW-02: approving is a significant action, so it is confirmed.
  /// The doctor is notified by the `onDoctorStatusChanged` trigger rather
  /// than from here, so the notification reflects the committed write.
  Future<void> _approveDoctor(DoctorModel doctor) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: tr('approve'),
      message: tr('approve_confirm', args: [doctor.name]),
      confirmLabel: tr('approve'),
      confirmColor: AppColors.success,
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final adminUid = ref.read(authStateProvider).valueOrNull?.uid ?? '';
      await ref.read(firestoreServiceProvider).updateDoctorStatus(
            doctorId: doctor.doctorId,
            status: AppConstants.doctorActive,
            approvedBy: adminUid,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('doctor_approved', args: [doctor.name]))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('error_generic'))),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  /// SRS A-FLOW-02: rejection carries a note the doctor sees on the awaiting
  /// screen, so the note is required rather than optional.
  Future<void> _showRejectDialog(DoctorModel doctor) async {
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await ConfirmationDialog.show(
      context,
      title: tr('reject'),
      message: tr('reject_doctor_confirm', args: [doctor.name]),
      confirmLabel: tr('reject'),
      confirmColor: AppColors.error,
      canConfirm: () => formKey.currentState?.validate() ?? false,
      extraContent: Form(
        key: formKey,
        child: TextFormField(
          controller: noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: tr('rejection_note'),
            border: const OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? tr('rejection_reason_required')
              : null,
        ),
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final adminUid = ref.read(authStateProvider).valueOrNull?.uid ?? '';
      await ref.read(firestoreServiceProvider).updateDoctorStatus(
            doctorId: doctor.doctorId,
            status: AppConstants.doctorRejected,
            rejectionNote: noteController.text.trim(),
            approvedBy: adminUid,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('error_generic'))),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
