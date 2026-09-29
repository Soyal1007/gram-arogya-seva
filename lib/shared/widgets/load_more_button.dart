import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/config/app_constants.dart';
import 'package:gram_aarogya_seva/core/providers/pagination_provider.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';

/// "Load more" control for a paginated list.
///
/// Renders nothing unless the list is full to its current limit — if fewer
/// rows came back than were asked for, there is nothing further to fetch and
/// an inert button would just be noise on a small screen.
class LoadMoreButton extends ConsumerWidget {
  const LoadMoreButton({
    super.key,
    required this.pageKey,
    required this.loadedCount,
  });

  /// One of [PageKeys].
  final String pageKey;

  /// How many rows the list is currently showing.
  final int loadedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = ref.watch(pageLimitProvider(pageKey));
    if (loadedCount < limit) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: OutlinedButton.icon(
          onPressed: () => ref.read(pageLimitProvider(pageKey).notifier).state =
              limit + AppConstants.paginationLimit,
          style: OutlinedButton.styleFrom(
            // Rural-first: still a comfortable tap target (DP-1).
            minimumSize: const Size(0, 52),
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
          ),
          icon: const Icon(Icons.expand_more_rounded),
          label: Text(tr('load_more')),
        ),
      ),
    );
  }
}
