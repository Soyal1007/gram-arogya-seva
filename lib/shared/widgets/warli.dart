import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gram_aarogya_seva/core/theme/app_colors.dart';

/// Warli painting, drawn in code.
///
/// Warli is the village art of the Maharashtra hills: rice-paste figures on a
/// geru mud wall, built from a circle (sun, moon, head), a triangle (body,
/// mountain, roof) and a line. This file is the app's one ornament: the
/// painted wall behind every home-screen header, and a band of figures holding
/// hands — the tarpa dance — that marks where the wall meets the page. Nothing
/// else in the app is decorated.

/// Which painting appears behind a header. Each role gets its own scene so
/// the home screens are recognisable at a glance.
enum MuralScene { village, clinic, register, office }

/// Geru header panel with a Warli painting behind the content and a dance
/// band along the bottom edge.
class MuralHeader extends StatelessWidget {
  const MuralHeader({
    super.key,
    required this.child,
    this.scene = MuralScene.village,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 24),
  });

  final Widget child;
  final MuralScene scene;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.muralGradient),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: CustomPaint(painter: _MuralPainter(scene)),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
          const WarliBand(),
        ],
      ),
    );
  }
}

/// A row of Warli figures holding hands, between two dotted lines.
class WarliBand extends StatelessWidget {
  const WarliBand({super.key, this.height = 30, this.onWall = true});

  final double height;

  /// Rice-white on the geru wall; geru on a light page.
  final bool onWall;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _BandPainter(onWall ? AppColors.onMural : AppColors.geru),
        ),
      ),
    );
  }
}

/// The app mark: a Warli figure inside a sun circle, with a small cross —
/// a person, cared for.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Drawing primitives
// ─────────────────────────────────────────────────────────────

Paint _fill(Color c) => Paint()
  ..color = c
  ..isAntiAlias = true;

Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke
  ..isAntiAlias = true;

/// One Warli figure standing on [base], [h] tall. [arms] picks the pose.
void _figure(
  Canvas c,
  Offset base,
  double h,
  Color color, {
  _Arms arms = _Arms.down,
  double lean = 0,
}) {
  final x = base.dx + lean * h * 0.1;
  final y = base.dy;
  final fill = _fill(color);
  final line = _stroke(color, math.max(1.2, h * 0.045));

  // Head
  c.drawCircle(Offset(x, y - h * 0.9), h * 0.1, fill);
  // Torso: two triangles meeting at the waist
  final waist = Offset(x, y - h * 0.5);
  c.drawPath(
    Path()
      ..moveTo(x - h * 0.17, y - h * 0.77)
      ..lineTo(x + h * 0.17, y - h * 0.77)
      ..lineTo(waist.dx, waist.dy)
      ..close(),
    fill,
  );
  c.drawPath(
    Path()
      ..moveTo(waist.dx, waist.dy)
      ..lineTo(x + h * 0.15, y - h * 0.27)
      ..lineTo(x - h * 0.15, y - h * 0.27)
      ..close(),
    fill,
  );
  // Legs, knees out
  c.drawPolygon(line, [
    Offset(x - h * 0.08, y - h * 0.27),
    Offset(x - h * 0.18, y - h * 0.13),
    Offset(x - h * 0.12, y),
  ]);
  c.drawPolygon(line, [
    Offset(x + h * 0.08, y - h * 0.27),
    Offset(x + h * 0.18, y - h * 0.13),
    Offset(x + h * 0.12, y),
  ]);
  // Arms
  final l = Offset(x - h * 0.16, y - h * 0.74);
  final r = Offset(x + h * 0.16, y - h * 0.74);
  switch (arms) {
    case _Arms.down:
      c.drawPolygon(line, [l, Offset(x - h * 0.28, y - h * 0.58), Offset(x - h * 0.3, y - h * 0.44)]);
      c.drawPolygon(line, [r, Offset(x + h * 0.28, y - h * 0.58), Offset(x + h * 0.3, y - h * 0.44)]);
    case _Arms.up:
      c.drawPolygon(line, [l, Offset(x - h * 0.3, y - h * 0.82), Offset(x - h * 0.32, y - h * 1.0)]);
      c.drawPolygon(line, [r, Offset(x + h * 0.3, y - h * 0.82), Offset(x + h * 0.32, y - h * 1.0)]);
    case _Arms.linked:
      // Hands reach exactly to the neighbours in a band spaced 0.62h apart.
      c.drawLine(l, Offset(x - h * 0.31, y - h * 0.62), line);
      c.drawLine(r, Offset(x + h * 0.31, y - h * 0.62), line);
    case _Arms.carry:
      // One arm holds a bag (the doctor's kit), one hangs.
      c.drawPolygon(line, [l, Offset(x - h * 0.28, y - h * 0.58), Offset(x - h * 0.3, y - h * 0.44)]);
      c.drawPolygon(line, [r, Offset(x + h * 0.3, y - h * 0.6), Offset(x + h * 0.34, y - h * 0.46)]);
      c.drawRect(
        Rect.fromLTWH(x + h * 0.26, y - h * 0.46, h * 0.2, h * 0.14),
        fill,
      );
  }
}

enum _Arms { down, up, linked, carry }

extension on Canvas {
  void drawPolygon(Paint p, List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final o in pts.skip(1)) {
      path.lineTo(o.dx, o.dy);
    }
    drawPath(path, p);
  }
}

void _sun(Canvas c, Offset o, double r, Color color) {
  c.drawCircle(o, r, _fill(color));
  final ray = _stroke(color, r * 0.12);
  for (var i = 0; i < 12; i++) {
    final a = i * math.pi / 6;
    c.drawLine(
      o + Offset(math.cos(a), math.sin(a)) * r * 1.35,
      o + Offset(math.cos(a), math.sin(a)) * r * 1.75,
      ray,
    );
  }
}

void _hut(Canvas c, Offset base, double w, Color color) {
  final line = _stroke(color, math.max(1.2, w * 0.04));
  final h = w * 0.55;
  // Walls
  c.drawRect(Rect.fromLTWH(base.dx - w / 2, base.dy - h, w, h), line);
  // Thatch roof
  c.drawPath(
    Path()
      ..moveTo(base.dx - w * 0.65, base.dy - h)
      ..lineTo(base.dx, base.dy - h - w * 0.5)
      ..lineTo(base.dx + w * 0.65, base.dy - h)
      ..close(),
    _fill(color),
  );
  // Door
  c.drawRect(
    Rect.fromLTWH(base.dx - w * 0.1, base.dy - h * 0.6, w * 0.2, h * 0.6),
    _fill(color),
  );
}

void _tree(Canvas c, Offset base, double h, Color color) {
  final line = _stroke(color, math.max(1.2, h * 0.035));
  final top = base - Offset(0, h);
  c.drawLine(base, top, line);
  for (var i = 1; i <= 4; i++) {
    final y = base.dy - h * (0.35 + i * 0.14);
    final span = h * (0.32 - i * 0.05);
    for (final s in [-1.0, 1.0]) {
      final tip = Offset(base.dx + s * span, y - h * 0.08);
      c.drawLine(Offset(base.dx, y), tip, line);
      c.drawCircle(tip, h * 0.035, _fill(color));
    }
  }
}

void _mountains(Canvas c, Offset base, double w, Color color) {
  final p = _fill(color);
  for (final (dx, s) in [(-0.3, 0.7), (0.05, 1.0), (0.38, 0.6)]) {
    final cx = base.dx + dx * w;
    final hw = w * 0.22 * s;
    c.drawPath(
      Path()
        ..moveTo(cx - hw, base.dy)
        ..lineTo(cx, base.dy - hw * 1.3)
        ..lineTo(cx + hw, base.dy)
        ..close(),
      p,
    );
  }
}

/// Sparse rice-paste dots, deterministic per scene.
void _dots(Canvas c, Size size, Color color, int seed) {
  final rnd = math.Random(seed);
  final p = _fill(color);
  for (var i = 0; i < 40; i++) {
    c.drawCircle(
      Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
      0.8 + rnd.nextDouble() * 1.2,
      p,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────

class _MuralPainter extends CustomPainter {
  _MuralPainter(this.scene);

  final MuralScene scene;

  @override
  void paint(Canvas canvas, Size size) {
    // Faint: the painting sits behind text and must never compete with it.
    final faint = AppColors.onMural.withValues(alpha: 0.16);
    final mid = AppColors.onMural.withValues(alpha: 0.24);
    final w = size.width;
    final h = size.height;
    final ground = h - 6;

    _dots(canvas, size, AppColors.onMural.withValues(alpha: 0.10), scene.index + 7);
    _sun(canvas, Offset(w - 46, 40), 14, mid);

    switch (scene) {
      case MuralScene.village:
        _mountains(canvas, Offset(w * 0.78, ground), w * 0.42, faint);
        _hut(canvas, Offset(w - 70, ground), 46, mid);
        _tree(canvas, Offset(w - 128, ground), 70, mid);
        _figure(canvas, Offset(w - 24, ground), 40, mid, arms: _Arms.up);
      case MuralScene.clinic:
        _mountains(canvas, Offset(w * 0.8, ground), w * 0.38, faint);
        _figure(canvas, Offset(w - 110, ground), 54, mid, arms: _Arms.carry);
        _figure(canvas, Offset(w - 62, ground), 42, mid);
        _figure(canvas, Offset(w - 28, ground), 32, mid, arms: _Arms.up);
      case MuralScene.register:
        _tree(canvas, Offset(w - 30, ground), 76, mid);
        _hut(canvas, Offset(w - 92, ground), 40, mid);
        _figure(canvas, Offset(w - 150, ground), 40, faint, arms: _Arms.up);
      case MuralScene.office:
        _mountains(canvas, Offset(w * 0.72, ground), w * 0.5, faint);
        _hut(canvas, Offset(w - 52, ground), 40, mid);
        _hut(canvas, Offset(w - 112, ground), 32, mid);
        _tree(canvas, Offset(w - 160, ground), 56, faint);
    }
  }

  @override
  bool shouldRepaint(_MuralPainter old) => old.scene != scene;
}

class _BandPainter extends CustomPainter {
  _BandPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = _fill(color.withValues(alpha: 0.85));
    // Dotted borders top and bottom, as painted with a stick tip.
    for (double x = 3; x < size.width; x += 7) {
      canvas.drawCircle(Offset(x, 1.6), 1.2, dot);
      canvas.drawCircle(Offset(x + 3.5, size.height - 1.6), 1.2, dot);
    }
    // Figures holding hands, centred.
    final fh = size.height - 8;
    final step = fh * 0.62;
    final count = (size.width / step).floor();
    final start = (size.width - (count - 1) * step) / 2;
    for (var i = 0; i < count; i++) {
      _figure(
        canvas,
        Offset(start + i * step, size.height - 4),
        fh,
        color,
        arms: _Arms.linked,
      );
    }
  }

  @override
  bool shouldRepaint(_BandPainter old) => old.color != color;
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final o = Offset(s / 2, s / 2);
    // Sun ring with rice-paste dots
    canvas.drawCircle(o, s * 0.46, _stroke(AppColors.onMural, s * 0.025));
    final dot = _fill(AppColors.zariBright);
    for (var i = 0; i < 24; i++) {
      final a = i * math.pi / 12;
      canvas.drawCircle(o + Offset(math.cos(a), math.sin(a)) * s * 0.4, s * 0.012, dot);
    }
    // Figure, arms raised
    _figure(canvas, Offset(s * 0.46, s * 0.8), s * 0.5, AppColors.onMural, arms: _Arms.up);
    // Small cross, top right of the figure
    final cross = _fill(AppColors.zariBright);
    final cx = s * 0.68;
    final cy = s * 0.36;
    final a = s * 0.11;
    final b = s * 0.036;
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: a, height: b), cross);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: b, height: a), cross);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => false;
}
