import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/models/village_model.dart';
import 'package:gram_aarogya_seva/core/utils/validators.dart';
import 'package:gram_aarogya_seva/shared/widgets/large_button.dart';
import 'package:gram_aarogya_seva/shared/widgets/confirmation_dialog.dart';
import 'package:gram_aarogya_seva/features/admin/admin_providers.dart';

/// SRS §11.1 A-FLOW-01 Step 4: Village CRUD.
class VillageManagementScreen extends ConsumerWidget {
  const VillageManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villagesAsync = ref.watch(allVillagesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('manage_villages'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVillageDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(tr('add_village')),
      ),
      body: villagesAsync.when(
        data: (villages) {
          if (villages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 64, color: AppColors.disabled),
                  const SizedBox(height: 16),
                  Text(tr('no_results'), style: AppTextStyles.titleLarge),
                  const SizedBox(height: 24),
                  LargeButton(
                    label: tr('add_village'),
                    icon: Icons.add,
                    onPressed: () => _showAddVillageDialog(context, ref),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: villages.length,
            itemBuilder: (context, index) => _VillageCard(village: villages[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(tr('error_generic'))),
      ),
    );
  }

  void _showAddVillageDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final talukaCtrl = TextEditingController();
    final districtCtrl = TextEditingController();
    final stateCtrl = TextEditingController(text: 'Maharashtra');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('add_village'), style: AppTextStyles.headlineSmall),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: tr('village_name_label')),
                  validator: (v) => Validators.validateRequired(v, 'Village Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: talukaCtrl,
                  decoration: InputDecoration(labelText: tr('taluka_label')),
                  validator: (v) => Validators.validateRequired(v, 'Taluka'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: districtCtrl,
                  decoration: InputDecoration(labelText: tr('district_label')),
                  validator: (v) => Validators.validateRequired(v, 'District'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: stateCtrl,
                  decoration: InputDecoration(labelText: tr('state_label')),
                  validator: (v) => Validators.validateRequired(v, 'State'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final uid = ref.read(authStateProvider).valueOrNull?.uid ?? '';
              await ref.read(firestoreServiceProvider).createVillage(
                    VillageModel(
                      villageId: '',
                      name: nameCtrl.text.trim(),
                      taluka: talukaCtrl.text.trim(),
                      district: districtCtrl.text.trim(),
                      state: stateCtrl.text.trim(),
                      createdBy: uid,
                    ),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
  }
}

class _VillageCard extends ConsumerWidget {
  final VillageModel village;
  const _VillageCard({required this.village});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: village.isActive
            ? BorderSide.none
            : const BorderSide(color: AppColors.disabled),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: village.isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.disabled.withValues(alpha: 0.2),
          child: Icon(
            Icons.location_on,
            color: village.isActive ? AppColors.primary : AppColors.disabled,
          ),
        ),
        title: Text(village.name, style: AppTextStyles.titleLarge),
        subtitle: Text(
          '${village.taluka}, ${village.district}, ${village.state}',
          style: AppTextStyles.caption,
        ),
        trailing: village.isActive
            ? IconButton(
                icon: const Icon(Icons.block, color: AppColors.error),
                tooltip: tr('deactivate'),
                onPressed: () async {
                  final confirmed = await ConfirmationDialog.show(
                    context,
                    title: tr('deactivate'),
                    message: tr('deactivate_confirm', args: [village.name]),
                    confirmColor: AppColors.error,
                  );
                  if (confirmed != true) return;
                  final uid =
                      ref.read(authStateProvider).valueOrNull?.uid ?? '';
                  // DP-5: villages are deactivated, never deleted, so
                  // historical appointments keep resolving their location.
                  await ref
                      .read(firestoreServiceProvider)
                      .deactivateVillage(village.villageId, uid);
                },
              )
            : Chip(
                label: Text(tr('label_inactive')),
                backgroundColor: Colors.transparent,
              ),
      ),
    );
  }
}
