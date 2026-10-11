import 'package:flutter/material.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';

/// The zari border — the app's one ornament.
///
/// A Paithani sari is recognised by its gold border: a solid band edged with a
/// small repeating motif. This draws that as a thin gold rule with a row of
/// diamonds, and is used only where a peacock header meets the page, so the
/// ornament marks structure rather than decorating content.
class ZariBorder extends StatelessWidget {
  const ZariBorder({super.key, this.height = 12, this.onDark = true});

  final double height;

  /// On a peacock surface the motif uses the bright gold; on porcelain it uses
  /// the deeper gold so it keeps contrast.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _ZariPainter(onDark: onDark)),
      ),
    );
  }
}

class _ZariPainter extends CustomPainter {
  _ZariPainter({required this.onDark});

  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final gold = onDark ? AppColors.zariBright : AppColors.zari;
    final rule = Paint()
      ..color = gold
      ..strokeWidth = 1.2;
    final fill = Paint()..color = gold;

    final h = size.height;
    // Two rules framing the motif band.
    canvas.drawLine(Offset(0, 0.6), Offset(size.width, 0.6), rule);
    canvas.drawLine(Offset(0, h - 0.6), Offset(size.width, h - 0.6), rule);

    // Diamonds, centred so the pattern is symmetric at any width.
    final d = h * 0.32; // half-diagonal
    const gap = 14.0;
    final count = (size.width / gap).floor();
    final start = (size.width - (count - 1) * gap) / 2;
    final cy = h / 2;
    for (var i = 0; i < count; i++) {
      final cx = start + i * gap;
      final small = i.isOdd;
      final r = small ? d * 0.5 : d;
      final path = Path()
        ..moveTo(cx, cy - r)
        ..lineTo(cx + r, cy)
        ..lineTo(cx, cy + r)
        ..lineTo(cx - r, cy)
        ..close();
      canvas.drawPath(path, fill);
    }
  }

  @override
  bool shouldRepaint(_ZariPainter old) => old.onDark != onDark;
}

/// Peacock header panel ending in a zari border — the top of every role's
/// home screen and of the sign-in flow.
class PaithaniHeader extends StatelessWidget {
  const PaithaniHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.healingGradient),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: padding, child: child),
          const ZariBorder(),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// The app mark: a medical cross inside a double gold ring.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.zariBright, width: 1.5),
      ),
      padding: EdgeInsets.all(size * 0.07),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.onPrimary.withValues(alpha: 0.08),
          border: Border.all(
            color: AppColors.zariBright.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Icon(
          Icons.local_hospital_rounded,
          size: size * 0.48,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}
