import 'package:flutter/material.dart';

/// Page indicator that follows the finger. It is painted straight from the PageController
/// (no rebuilds, no layout changes), so the active "pill" stretches smoothly while swiping.
class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.controller,
    required this.count,
    required this.activeColor,
    required this.inactiveColor,
    this.dotSize = 8,
    this.gap = 8,
  });
  final PageController controller;
  final int count;
  final Color activeColor, inactiveColor;
  final double dotSize, gap;

  @override
  Widget build(BuildContext context) {
    final activeExtra = dotSize * 2; // the active dot is 3x as wide as an idle one
    return Semantics(
      label: 'Page indicator',
      child: CustomPaint(
        size: Size(count * dotSize + activeExtra + (count - 1) * gap, dotSize),
        painter: _DotsPainter(controller, count, activeColor, inactiveColor, dotSize, gap, activeExtra),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.controller, this.count, this.active, this.inactive, this.dot, this.gap, this.extra)
    : super(repaint: controller);
  final PageController controller;
  final int count;
  final Color active, inactive;
  final double dot, gap, extra;

  @override
  void paint(Canvas canvas, Size size) {
    final page = (controller.hasClients && controller.position.haveDimensions)
        ? (controller.page ?? controller.initialPage.toDouble())
        : controller.initialPage.toDouble();
    var x = 0.0;
    for (var i = 0; i < count; i++) {
      final near = 1.0 - (page - i).abs().clamp(0.0, 1.0).toDouble(); // 1 = this page, 0 = away
      final w = dot + extra * near;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, 0, w, dot), Radius.circular(dot / 2)),
        Paint()..color = Color.lerp(inactive, active, near)!,
      );
      x += w + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) =>
      old.count != count || old.active != active || old.inactive != inactive || old.controller != controller;
}
