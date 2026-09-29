import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/shared/widgets/confirmation_dialog.dart';
import 'package:gram_aarogya_seva/features/admin/admin_providers.dart';

/// SRS §11.1 A-FLOW-01 Step 5: Role Management — search user by phone, change role.
class RoleManagementScreen extends ConsumerWidget {
  const RoleManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(userSearchQueryProvider);
    final resultsAsync = ref.watch(userSearchResultsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('role_management'))),
      body: Column(
        children: [
          // Search by phone
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: AppTextStyles.bodyLarge,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: tr('search_by_phone'),
                prefixIcon: const Icon(Icons.phone),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => ref
                            .read(userSearchQueryProvider.notifier)
                            .state = '',
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => ref
                  .read(userSearchQueryProvider.notifier)
                  .state = value.trim(),
            ),
          ),

          // Results
          Expanded(
            child: query.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.manage_accounts, size: 64,
                            color: AppColors.disabled.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(tr('search_phone_manage_roles'),
                            style: AppTextStyles.bodyLarge),
                      ],
                    ),
                  )
                : resultsAsync.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return Center(
                          child: Text(tr('no_results'),
                              style: AppTextStyles.titleLarge),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: users.length,
                        itemBuilder: (_, i) {
                          final user = users[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        child: const Icon(Icons.person,
                                            color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.name.isNotEmpty
                                                  ? user.name
                                                  : tr('unnamed_user'),
                                              style: AppTextStyles.titleLarge,
                                            ),
                                            Text(user.phone,
                                                style: AppTextStyles.bodyMedium),
                                          ],
                                        ),
                                      ),
                                      Chip(
                                        label: Text(tr('role_${user.role}'),
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600)),
                                        backgroundColor: _roleColor(user.role)
                                            .withValues(alpha: 0.15),
                                        side: BorderSide(
                                            color: _roleColor(user.role)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(tr('change_role'),
                                      style: AppTextStyles.caption),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    // `doctor` is deliberately not assignable
                                    // here. A doctor account is created by
                                    // submitDoctorRegistration together with
                                    // an ABDM-verified profile; granting the
                                    // role alone produces an account with no
                                    // doctors/{uid} document, which strands
                                    // the user on the awaiting screen with no
                                    // way forward (Assessment §11.16).
                                    children: [
                                      AppConstants.rolePatient,
                                      AppConstants.roleOperator,
                                      AppConstants.roleAdmin,
                                    ]
                                        .where((r) => r != user.role)
                                        .map((role) => ActionChip(
                                              label: Text(tr('role_$role')),
                                              onPressed: () async {
                                                final confirmed =
                                                    await ConfirmationDialog
                                                        .show(
                                                  context,
                                                  title: tr('change_role'),
                                                  message: tr(
                                                    'change_role_confirm',
                                                    args: [
                                                      user.name.isNotEmpty
                                                          ? user.name
                                                          : user.phone,
                                                      tr('role_$role'),
                                                    ],
                                                  ),
                                                  confirmLabel:
                                                      tr('change_role'),
                                                );
                                                if (confirmed != true) return;
                                                await ref
                                                    .read(
                                                        firestoreServiceProvider)
                                                    .updateUserRole(
                                                        user.uid, role);
                                                ref.invalidate(
                                                    userSearchResultsProvider);
                                              },
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text(tr('error_generic'))),
                  ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return AppColors.error;
      case 'doctor': return AppColors.secondary;
      case 'operator': return AppColors.info;
      case 'patient': return AppColors.primary;
      default: return AppColors.disabled;
    }
  }
}
