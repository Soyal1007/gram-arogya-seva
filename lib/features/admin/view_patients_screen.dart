import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/providers/reference_data_providers.dart';
import 'package:gram_aarogya_seva/core/providers/pagination_provider.dart';
import 'package:gram_aarogya_seva/shared/widgets/load_more_button.dart';
import 'package:gram_aarogya_seva/features/admin/admin_providers.dart';

/// SRS §11.1 A-FLOW-01: View/search patients by name prefix.
class ViewPatientsScreen extends ConsumerWidget {
  const ViewPatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(patientSearchQueryProvider);
    final resultsAsync = ref.watch(patientSearchResultsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('view_patients'))),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: tr('search_by_name'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => ref
                            .read(patientSearchQueryProvider.notifier)
                            .state = '',
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => ref
                  .read(patientSearchQueryProvider.notifier)
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
                        Icon(Icons.search, size: 64,
                            color: AppColors.disabled.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(tr('type_name_to_search'),
                            style: AppTextStyles.bodyLarge),
                      ],
                    ),
                  )
                : resultsAsync.when(
                    data: (patients) {
                      if (patients.isEmpty) {
                        return Center(
                          child: Text(tr('no_results'),
                              style: AppTextStyles.titleLarge),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: patients.length + 1,
                        itemBuilder: (_, i) {
                          if (i == patients.length) {
                            return LoadMoreButton(
                              pageKey: PageKeys.adminPatients,
                              loadedCount: patients.length,
                            );
                          }
                          final p = patients[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.info.withValues(alpha: 0.1),
                                child: Icon(Icons.person,
                                    color: AppColors.info),
                              ),
                              title: Text(p.name,
                                  style: AppTextStyles.titleLarge),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      tr('dob_gender_value',
                                          args: [p.dob, p.gender]),
                                      style: AppTextStyles.caption),
                                  if (p.mobile != null)
                                    Text(
                                        tr('mobile_value',
                                            args: [p.mobile!]),
                                        style: AppTextStyles.caption),
                                  Text(
                                      tr('village_value', args: [
                                        ref.watch(villageNameProvider(
                                                p.villageId)) ??
                                            tr('loading')
                                      ]),
                                      style: AppTextStyles.caption),
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
}
