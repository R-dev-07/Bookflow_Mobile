import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../widgets/motion.dart';

/// Shows the animated [SplashScreen] on top of [child] at launch.
///
/// [child] (the real app, including Clerk's session check) is built underneath straight away,
/// so the app keeps loading while the animation plays and there is no extra wait afterwards.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});
  final Widget child;

  /// Flips to true once the splash has left the screen. The landing screen waits for this
  /// before it plays its entrance animation, so the two never compete.
  static final ValueNotifier<bool> finished = ValueNotifier<bool>(false);

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
    value: 1, // 1 = splash fully visible
  );
  bool _gone = SplashGate.finished.value;

  Future<void> _leave() async {
    if (_gone || !mounted) return;
    if (reduceMotion(context)) {
      _exit.value = 0;
    } else {
      await _exit.reverse();
    }
    if (!mounted) return;
    setState(() => _gone = true);
    SplashGate.finished.value = true;
  }

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _exit,
          builder: (context, child) {
            final v = Curves.easeInOut.transform(_exit.value);
            return Opacity(
              opacity: v,
              child: Transform.scale(scale: 1.0 + (1 - v) * 0.07, child: child),
            );
          },
          child: SplashScreen(onDone: _leave),
        ),
      ],
    );
  }
}

/// Brand splash. Mirrors the reference animation: a crimson blackletter "B" pops in while thin
/// line-art (a spiky burst, two circles and a blade) rotates and sweeps outward around it, then
/// everything clears and the B settles. The wordmark fades in underneath.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF060505);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  );
  bool _started = false;
  bool _reduce = false;
  bool _doneCalled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduce = reduceMotion(context);
    if (_reduce) _c.duration = const Duration(milliseconds: 1500);
    _c.forward().whenComplete(() async {
      await Future<void>.delayed(const Duration(milliseconds: 260));
      _finish();
    });
  }

  void _finish() {
    if (_doneCalled || !mounted) return;
    _doneCalled = true;
    widget.onDone();
  }

  /// Tap to skip: fast-forward to the end of the animation, then leave.
  void _skip() {
    if (_doneCalled || _c.value >= 0.98) return;
    _c.animateTo(1, duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double _seg(double t, double a, double b, [Curve curve = Curves.linear]) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0).toDouble());

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: ColoredBox(
          color: _bg,
          child: LayoutBuilder(
            builder: (context, box) {
              final u = math.min(box.maxWidth, box.maxHeight);
              final markW = (u * 0.34).clamp(120.0, 190.0).toDouble();
              final markH = markW * 640 / 582;
              return AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final t = _c.value;
                  return _reduce ? _reducedFrame(t, markW, markH) : _fullFrame(t, box, markW, markH);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _mark(double w) => Image.asset(
    'assets/images/bookflow_mark.png',
    width: w,
    filterQuality: FilterQuality.high,
    semanticLabel: 'BookFlow',
  );

  Widget _wordmark(double v) {
    return Opacity(
      opacity: v,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'BookFlow',
            style: TextStyle(
              color: AppColors.brandCream,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 10 - 8.5 * v,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'BOOK  ·  CELEBRATE  ·  FLOW',
            style: TextStyle(
              color: AppColors.brandCream.withValues(alpha: 0.55),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reducedFrame(double t, double markW, double markH) {
    final v = Curves.easeOut.transform(t.clamp(0.0, 1.0).toDouble());
    return Center(
      child: Opacity(
        opacity: v,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_mark(markW), const SizedBox(height: 28), _wordmark(1)],
        ),
      ),
    );
  }

  Widget _fullFrame(double t, BoxConstraints box, double markW, double markH) {
    // The B pops in with a little overshoot and a slight un-rotate.
    final pop = _seg(t, 0.05, 0.36, Curves.easeOutBack);
    final fadeIn = _seg(t, 0.04, 0.14);
    final settle = _seg(t, 0.36, 0.55, Curves.easeInOut);
    final scale = (0.12 + 0.88 * pop) * (1 + 0.035 * math.sin(settle * math.pi));
    final turn = (1 - _seg(t, 0.05, 0.40, Curves.easeOutCubic)) * -0.22;
    final glow = math.sin(_seg(t, 0.10, 0.80) * math.pi);
    final wm = _seg(t, 0.78, 0.97, Curves.easeOutCubic);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Soft crimson bloom behind the mark.
        Center(
          child: Opacity(
            opacity: (0.55 * glow).clamp(0.0, 1.0).toDouble(),
            child: Container(
              width: markW * 3.2,
              height: markW * 3.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.brandCrimson.withValues(alpha: 0.55), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        // The line-art.
        CustomPaint(painter: _BurstPainter(t), child: const SizedBox.expand()),
        // The B.
        Center(
          child: Opacity(
            opacity: fadeIn,
            child: Transform.rotate(
              angle: turn,
              child: Transform.scale(scale: scale, child: _mark(markW)),
            ),
          ),
        ),
        // Wordmark.
        Center(
          child: Transform.translate(
            offset: Offset(0, markH / 2 + 54 + (1 - wm) * 14),
            child: _wordmark(wm),
          ),
        ),
      ],
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t);
  final double t;

  static double _seg(double t, double a, double b, [Curve curve = Curves.linear]) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0).toDouble());

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final u = size.shortestSide;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // 1) Spiky burst: grows out from the mark while spinning, then flies outward and fades.
    final grow = _seg(t, 0.03, 0.46, Curves.easeOutCubic);
    final fly = _seg(t, 0.46, 0.86, Curves.easeInCubic);
    final burstA = (grow * (1 - fly)).clamp(0.0, 1.0).toDouble();
    if (burstA > 0.01) {
      final r = u * (0.10 + 0.27 * grow + 0.32 * fly);
      final rot = -0.9 + 2.4 * _seg(t, 0.03, 0.90, Curves.easeInOutCubic);
      const n = 14;
      final path = Path();
      for (var i = 0; i < n * 2; i++) {
        final rr = i.isEven ? r : r * 0.74;
        final a = rot + i * math.pi / n;
        final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        line
          ..strokeWidth = 1.6
          ..color = Colors.white.withValues(alpha: 0.85 * burstA),
      );
    }

    // 2) Two overlapping circles (a vesica) that swell and drift apart.
    final cg = _seg(t, 0.02, 0.50, Curves.easeOutCubic);
    final cf = _seg(t, 0.40, 0.72, Curves.easeIn);
    final circleA = (cg * (1 - cf)).clamp(0.0, 1.0).toDouble();
    if (circleA > 0.01) {
      final r = u * (0.18 + 0.20 * cg + 0.10 * cf);
      final axis = 0.6 + 1.1 * _seg(t, 0.02, 0.86, Curves.easeInOut);
      final off = Offset(math.cos(axis), math.sin(axis)) * (u * (0.07 + 0.10 * cg + 0.12 * cf));
      line
        ..strokeWidth = 1.3
        ..color = Colors.white.withValues(alpha: 0.55 * circleA);
      canvas.drawCircle(c + off, r, line);
      canvas.drawCircle(c - off, r, line);
    }

    // 3) The blade: a long thin rhombus that swings from a diagonal to flat, stretching as it goes.
    final b1 = _seg(t, 0.04, 0.38, Curves.easeOutCubic);
    final b2 = _seg(t, 0.30, 0.82, Curves.easeInOutCubic);
    final bladeA = (b1 * (1 - _seg(t, 0.64, 0.84))).clamp(0.0, 1.0).toDouble();
    if (bladeA > 0.01) {
      final theta = -1.0 * (1 - b2);
      final len = u * (0.30 + 0.34 * b1 + 0.55 * b2);
      final wid = u * (0.075 * (1 - b2) + 0.012);
      final cosT = math.cos(theta), sinT = math.sin(theta);
      Offset rot(double x, double y) => c + Offset(x * cosT - y * sinT, x * sinT + y * cosT);
      final blade = Path()
        ..moveTo(rot(-len, 0).dx, rot(-len, 0).dy)
        ..lineTo(rot(0, -wid).dx, rot(0, -wid).dy)
        ..lineTo(rot(len, 0).dx, rot(len, 0).dy)
        ..lineTo(rot(0, wid).dx, rot(0, wid).dy)
        ..close();
      canvas.drawPath(
        blade,
        line
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.9 * bladeA),
      );
    }

    // 4) Big arcs sweeping in from the left and right edges.
    final sweep = _seg(t, 0.44, 0.74, Curves.easeOutCubic);
    final sweepA = (sweep * (1 - _seg(t, 0.68, 0.86))).clamp(0.0, 1.0).toDouble();
    if (sweepA > 0.01) {
      final r = u * 0.95;
      final gap = u * (0.62 - 0.46 * sweep);
      line
        ..strokeWidth = 2.6
        ..color = Colors.white.withValues(alpha: 0.9 * sweepA);
      for (final dir in [-1.0, 1.0]) {
        final centre = Offset(c.dx + dir * (r + gap), c.dy);
        final start = dir < 0 ? -0.42 : math.pi - 0.42;
        canvas.drawArc(Rect.fromCircle(center: centre, radius: r), start, 0.84, false, line);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}
