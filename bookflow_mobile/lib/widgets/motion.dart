import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// True when the user asked the OS to reduce motion (accessibility setting).
/// Convention in this app: reduced motion = no movement/scaling, but short fades stay.
bool reduceMotion(BuildContext context) => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Shared timing and easing so every animation feels like one product.
class AppMotion {
  AppMotion._();

  /// Strong ease-out: responsive start, soft landing. Use for things entering or responding.
  static const Curve outStrong = Cubic(0.23, 1, 0.32, 1);

  static const Duration press = Duration(milliseconds: 90); // finger down: quick
  static const Duration release = Duration(milliseconds: 180); // finger up: settles
  static const Duration fade = Duration(milliseconds: 200);
  static const Duration reducedFade = Duration(milliseconds: 120);

  static Duration fadeFor(BuildContext context) => reduceMotion(context) ? reducedFade : fade;
}

/// Fades and rises 8 px into place the first time it appears. [index] staggers siblings
/// (30 ms apart, first 5 only) so the whole group settles within ~300 ms.
/// With reduced motion it only fades (no movement, no stagger).
/// Use sparingly: first-time / uncached moments only, never on content the user sees every visit.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: AppMotion.outStrong);
  Timer? _timer;
  bool _started = false;
  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduce = reduceMotion(context);
    _c.duration = _reduce ? AppMotion.reducedFade : const Duration(milliseconds: 180);
    final steps = widget.index < 0 ? 0 : (widget.index > 4 ? 4 : widget.index);
    if (_reduce || steps == 0) {
      _c.forward();
    } else {
      _timer = Timer(Duration(milliseconds: 30 * steps), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: _reduce
        ? widget.child
        : AnimatedBuilder(
            animation: _a,
            child: widget.child,
            builder: (context, child) =>
                Transform.translate(offset: Offset(0, (1 - _a.value) * 8), child: child),
          ),
  );
}

/// Apple-style springs described by *damping ratio* (1.0 = no overshoot) and *response*
/// (seconds to reach the target; not a duration). Springs are interruptible and carry velocity,
/// which is what makes motion feel physical. Default to damping 1.0; add bounce (~0.8)
/// only after a gesture that carried momentum (a flick or throw).
class AppSpring {
  AppSpring._();

  static SpringDescription of({required double response, double damping = 1.0}) {
    final omega = 2 * math.pi / response;
    return SpringDescription.withDampingRatio(mass: 1, stiffness: omega * omega, ratio: damping);
  }

  static final SpringDescription press = of(response: 0.18);
  static final SpringDescription settle = of(response: 0.3);
  static final SpringDescription momentum = of(response: 0.35, damping: 0.8);

  /// Entrance for sheets opened by a tap (no momentum, so no overshoot); exit uses the strong ease-out.
  static const SpringCurve sheetCurve = SpringCurve(response: 0.35);
  static final AnimationStyle sheet = AnimationStyle(
    curve: sheetCurve,
    duration: sheetCurve.duration,
    reverseCurve: AppMotion.outStrong.flipped,
    reverseDuration: const Duration(milliseconds: 220),
  );
}

/// A spring's step response as an animation curve, for APIs that only accept a [Curve]/duration
/// (e.g. route and bottom-sheet animations). Use together with [duration].
class SpringCurve extends Curve {
  const SpringCurve({this.response = 0.35, this.damping = 1.0});
  final double response;
  final double damping;

  double get _omega => 2 * math.pi / response;

  /// Time after which the spring is visually at rest.
  Duration get duration => Duration(milliseconds: (7 / (damping * _omega) * 1000).round());

  @override
  double transformInternal(double t) {
    final time = t * 7 / (damping * _omega);
    final w = _omega;
    if (damping >= 1) return 1 - math.exp(-w * time) * (1 + w * time);
    final wd = w * math.sqrt(1 - damping * damping);
    return 1 -
        math.exp(-damping * w * time) * (math.cos(wd * time) + (damping * w / wd) * math.sin(wd * time));
  }
}

/// Press feedback without a ripple. Reacts on finger-DOWN with a spring to 97% and springs back
/// on release, always starting from the current on-screen value and velocity, so quick taps and
/// re-presses never jump. With reduced motion it dims slightly instead.
/// Uses a raw pointer Listener so it never competes with the child's own tap handling.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: 1);
  bool _down = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _set(bool v) {
    if (!widget.enabled || _down == v) return;
    setState(() => _down = v);
    if (reduceMotion(context)) return;
    _c.animateWith(
      SpringSimulation(v ? AppSpring.press : AppSpring.settle, _c.value, v ? 0.97 : 1.0, _c.velocity),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: reduceMotion(context)
          ? AnimatedOpacity(opacity: _down ? 0.7 : 1, duration: AppMotion.press, child: widget.child)
          : AnimatedBuilder(
              animation: _c,
              child: widget.child,
              builder: (context, child) => Transform.scale(scale: _c.value, child: child),
            ),
    );
  }
}
