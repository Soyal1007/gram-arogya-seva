import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/models/notification_model.dart';
import 'package:gram_aarogya_seva/core/providers/auth_providers.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';
import 'package:gram_aarogya_seva/core/utils/date_utils.dart';

/// The notification inbox — SRS §7.8.
///
/// Every entry was written by a Cloud Function at the moment the event
/// happened, already localised into the recipient's language (copy cannot be
/// re-translated later without the original parameters, which are not kept).
///
/// This is the in-app half of notifications. FCM push delivery is the
/// remaining piece (roadmap P2-15); until then the inbox and the live
/// Firestore streams are how users learn about status changes, which is why
/// it exists ahead of push.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('notifications')),
        actions: [
          notificationsAsync.maybeWhen(
            data: (items) {
              final unread = items.where((n) => !n.isRead).toList();
              if (unread.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () async {
                  final service = ref.read(firestoreServiceProvider);
                  await Future.wait(unread.map(
                    (n) => service.markNotificationRead(n.notificationId),
                  ));
                },
                child: Text(tr('mark_all_read')),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64,
                      color: AppColors.disabled.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(tr('no_notifications'),
                      style: AppTextStyles.bodyLarge),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) => _NotificationTile(notification: items[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(tr('error_generic'))),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final NotificationModel notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = !notification.isRead;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isUnread
          ? AppColors.primary.withValues(alpha: 0.06)
          : AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _tone(notification.type).withValues(alpha: 0.15),
          child: Icon(_icon(notification.type),
              color: _tone(notification.type)),
        ),
        title: Text(
          notification.title,
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message, style: AppTextStyles.bodyMedium),
            if (notification.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                AppDateUtils.toDisplayDate(
                  AppDateUtils.toSchemaDate(notification.createdAt!),
                ),
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
        trailing: isUnread
            ? const Icon(Icons.circle, size: 10, color: AppColors.primary)
            : null,
        onTap: isUnread
            ? () => ref
                .read(firestoreServiceProvider)
                .markNotificationRead(notification.notificationId)
            : null,
      ),
    );
  }

  IconData _icon(String type) {
    if (type.startsWith('doctor_')) return Icons.medical_services_outlined;
    if (type.contains('cancel')) return Icons.event_busy_outlined;
    if (type.contains('reject')) return Icons.cancel_outlined;
    if (type.contains('complete')) return Icons.check_circle_outline;
    if (type.contains('reminder')) return Icons.alarm;
    return Icons.event_available_outlined;
  }

  Color _tone(String type) {
    if (type.contains('reject') || type.contains('cancel')) {
      return AppColors.error;
    }
    if (type.contains('approved') || type.contains('accepted')) {
      return AppColors.success;
    }
    if (type.contains('complete')) return AppColors.statusCompleted;
    return AppColors.info;
  }
}
