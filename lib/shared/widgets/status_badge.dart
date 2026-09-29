import 'package:flutter/material.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';

/// Status badge — Design System §5 StatusBadge.
/// Uses high-chroma tonal containers. No 1px borders.
/// Pending: tertiary, Accepted: secondary, Completed: primary, Rejected: error.
/// SRS §9 shared widget contract.
class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;

  const StatusBadge({
    super.key,
    required this.status,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = AppColors.statusColor(status);
    final bgColor = AppColors.statusBgColor(status);
    final statusIcon = _statusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusIcon != null) ...[
            Icon(statusIcon, size: 16, color: fgColor),
            const SizedBox(width: 6),
          ],
          Text(
            label ?? _displayLabel(status),
            style: AppTextStyles.caption.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData? _statusIcon(String status) {
    switch (status) {
      case 'pending':
      case 'pending_approval':
        return Icons.schedule_rounded;
      case 'accepted':
      case 'active':
        return Icons.check_rounded;
      case 'completed':
        return Icons.done_all_rounded;
      case 'rejected':
        return Icons.close_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'no_show':
        return Icons.person_off_rounded;
      case 'inactive':
        return Icons.pause_circle_outline;
      default:
        return null;
    }
  }

  String _displayLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      case 'pending_approval':
        return 'Pending';
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      default:
        return status;
    }
  }
}
