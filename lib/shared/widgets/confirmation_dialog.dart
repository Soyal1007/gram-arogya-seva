import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gram_aarogya_seva/core/theme/app_text_styles.dart';

/// Reusable confirmation dialog for destructive or significant actions.
/// SRS §9 shared widget contract, §13.6 manual-test checklist.
///
/// [show] resolves to `true` only when the user confirms, so the caller runs
/// the action itself and can await, catch and report its outcome. The earlier
/// `onConfirm` callback form fired the action without awaiting and popped
/// immediately, which reported success for writes that had actually been
/// rejected (TECHNICAL_ASSESSMENT.md §11.14).
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmColor,
    this.extraContent,
    this.canConfirm,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;

  /// Extra widget shown below the message — typically an input the action
  /// needs, such as a rejection reason.
  final Widget? extraContent;

  /// Optional gate run when the user taps confirm. Returning false keeps the
  /// dialog open, which is how a required field inside [extraContent] blocks
  /// confirmation.
  final bool Function()? canConfirm;

  /// Shows the dialog. Resolves to `true` on confirm, `false`/null otherwise.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    Color? confirmColor,
    Widget? extraContent,
    bool Function()? canConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel ?? tr('confirm'),
        cancelLabel: cancelLabel ?? tr('cancel'),
        confirmColor: confirmColor,
        extraContent: extraContent,
        canConfirm: canConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title, style: AppTextStyles.headlineSmall),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: AppTextStyles.bodyLarge),
            if (extraContent != null) ...[
              const SizedBox(height: 16),
              extraContent!,
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel, style: AppTextStyles.bodyLarge),
        ),
        ElevatedButton(
          onPressed: () {
            if (canConfirm != null && !canConfirm!()) return;
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
