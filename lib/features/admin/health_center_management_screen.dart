import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/models/health_center_model.dart';
import 'package:gram_aarogya_seva/core/utils/validators.dart';
import 'package:gram_aarogya_seva/shared/widgets/confirmation_dialog.dart';
import 'package:gram_aarogya_seva/features/admin/admin_providers.dart';

/// SRS §11.1 A-FLOW-01: Health Centre CRUD.
class HealthCenterManagementScreen extends ConsumerStatefulWidget {
  const HealthCenterManagementScreen({super.key});

  @override
  ConsumerState<HealthCenterManagementScreen> createState() =>
      _HealthCenterManagementScreenState();
}

class _HealthCenterManagementScreenState
    extends ConsumerState<HealthCenterManagementScreen> {
  String? _selectedVillageId;

  @override
  Widget build(BuildContext context) {
    final villagesAsync = ref.watch(allVillagesProvider);
    final centersAsync = ref.watch(allHealthCentersProvider(_selectedVillageId));

    return Scaffold(
      appBar: AppBar(title: Text(tr('manage_health_centers'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: Text(tr('add_health_center')),
      ),
      body: Column(
        children: [
          // Village filter dropdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: villagesAsync.when(
              data: (villages) => DropdownButtonFormField<String?>(
                decoration: InputDecoration(
                  labelText: tr('filter_by_village'),
                  prefixIcon: const Icon(Icons.filter_list),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(tr('all_villages'))),
                  ...villages
                      .where((v) => v.isActive)
                      .map((v) => DropdownMenuItem(
                            value: v.villageId,
                            child: Text(v.name),
                          )),
                ],
                onChanged: (v) => setState(() => _selectedVillageId = v),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Health centers list
          Expanded(
            child: centersAsync.when(
              data: (centers) {
                if (centers.isEmpty) {
                  return Center(
                    child: Text(tr('no_results'), style: AppTextStyles.titleLarge),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: centers.length,
                  itemBuilder: (_, i) => _CenterCard(center: centers[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(tr('error_generic'))),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? villageId;
    final formKey = GlobalKey<FormState>();

    final villagesAsync = ref.read(allVillagesProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('add_health_center_title'), style: AppTextStyles.headlineSmall),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: tr('centre_name')),
                  validator: (v) => Validators.validateRequired(v, 'Name'),
                ),
                const SizedBox(height: 12),
                villagesAsync.when(
                  data: (villages) => DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: tr('village_label')),
                    items: villages
                        .where((v) => v.isActive)
                        .map((v) => DropdownMenuItem(
                              value: v.villageId,
                              child: Text(v.name),
                            ))
                        .toList(),
                    validator: (v) =>
                        v == null ? tr('select_village_error') : null,
                    onChanged: (v) => villageId = v,
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => Text(tr('error_loading_villages')),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: InputDecoration(labelText: tr('address_label')),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(labelText: tr('phone_label')),
                  keyboardType: TextInputType.phone,
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
              if (villageId == null) return;
              final uid = ref.read(authStateProvider).valueOrNull?.uid ?? '';
              await ref.read(firestoreServiceProvider).createHealthCenter(
                    HealthCenterModel(
                      centerId: '',
                      name: nameCtrl.text.trim(),
                      villageId: villageId!,
                      address: addressCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
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

class _CenterCard extends ConsumerWidget {
  final HealthCenterModel center;
  const _CenterCard({required this.center});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: center.isActive
              ? AppColors.secondary.withValues(alpha: 0.1)
              : AppColors.disabled.withValues(alpha: 0.2),
          child: Icon(Icons.local_hospital,
              color: center.isActive ? AppColors.secondary : AppColors.disabled),
        ),
        title: Text(center.name, style: AppTextStyles.titleLarge),
        subtitle: Text(center.address, style: AppTextStyles.caption),
        trailing: center.isActive
            ? IconButton(
                icon: const Icon(Icons.block, color: AppColors.error),
                tooltip: tr('deactivate'),
                onPressed: () async {
                  final confirmed = await ConfirmationDialog.show(
                    context,
                    title: tr('deactivate'),
                    message: tr('deactivate_confirm', args: [center.name]),
                    confirmColor: AppColors.error,
                  );
                  if (confirmed != true) return;
                  final uid =
                      ref.read(authStateProvider).valueOrNull?.uid ?? '';
                  await ref
                      .read(firestoreServiceProvider)
                      .deactivateHealthCenter(center.centerId, uid);
                },
              )
            : Chip(label: Text(tr('label_inactive'))),
      ),
    );
  }
}
