import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../widgets/motion.dart';
import '../tab_bar_spec.dart';

/// "Scrubber": an icon-only floating pill. Tap a tab, or drag your finger across the pill: the
/// highlight capsule follows 1:1, resists at the ends (rubber band), and on release is thrown to the
/// tab your momentum is heading for, carrying your finger's velocity into the spring.
class ScrubberTabBar extends StatefulWidget {
  const ScrubberTabBar({super.key, required this.tabs, required this.index, required this.onSelect});
  final List<TabSpec> tabs;
  final int index;
  final TabSelected onSelect;

  static const double height = 64;
  static const double bottomGap = 10;

  @override
  State<ScrubberTabBar> createState() => _ScrubberTabBarState();
}

class _ScrubberTabBarState extends State<ScrubberTabBar> with SingleTickerProviderStateMixin {
  // Capsule position measured in tab cells (0 = first tab). Unbounded so springs may overshoot.
  late final AnimationController _x = AnimationController.unbounded(
    vsync: this,
    value: widget.index.toDouble(),
  );
  double _cell = 72;
  double _raw = 0; // finger position in cells, before rubber-banding
  int _target = 0;
  int _lastTick = 0;
  bool _dragging = false;

  int get _n => widget.tabs.length;

  @override
  void initState() {
    super.initState();
    _target = widget.index;
    _lastTick = widget.index;
  }

  @override
  void didUpdateWidget(covariant ScrubberTabBar old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && !_dragging && _target != widget.index) {
      _target = widget.index;
      _springTo(widget.index.toDouble(), AppSpring.settle, _x.velocity);
    }
  }

  @override
  void dispose() {
    _x.dispose();
    super.dispose();
  }

  int _clampIndex(num v) => v < 0 ? 0 : (v > _n - 1 ? _n - 1 : v.round());

  void _springTo(double target, SpringDescription spring, double velocity) {
    if (reduceMotion(context)) {
      _x.value = target;
      return;
    }
    _x.animateWith(SpringSimulation(spring, _x.value, target, velocity));
  }

  /// Progressive resistance past the ends (Apple's rubber-band function), in pixels.
  double _rubber(double overshootPx, double dimension) =>
      (overshootPx * dimension * 0.55) / (dimension + 0.55 * overshootPx.abs());

  void _onTapUp(TapUpDetails d) {
    final i = _clampIndex((d.localPosition.dx / _cell).floorToDouble());
    _target = i;
    _springTo(i.toDouble(), AppSpring.settle, _x.velocity);
    selectTab(widget.index, i, widget.onSelect);
    _lastTick = i;
  }

  void _onDragStart(DragStartDetails d) {
    _dragging = true;
    _x.stop();
    _raw = _x.value;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _raw += d.delta.dx / _cell;
    final max = (_n - 1).toDouble();
    final dim = _cell * _n;
    double shown;
    if (_raw < 0) {
      shown = -_rubber(-_raw * _cell, dim) / _cell;
    } else if (_raw > max) {
      shown = max + _rubber((_raw - max) * _cell, dim) / _cell;
    } else {
      shown = _raw;
    }
    _x.value = shown;
    final nearest = _clampIndex(shown);
    if (nearest != _lastTick) {
      _lastTick = nearest;
      HapticFeedback.selectionClick(); // a detent as you cross each tab
    }
  }

  void _onDragEnd(DragEndDetails d) {
    _dragging = false;
    final v = d.velocity.pixelsPerSecond.dx / _cell; // cells per second
    // Project where the motion would coast to (decelerationRate 0.99), then pick the nearest tab.
    final projected = _x.value + (v / 1000) * 0.99 / (1 - 0.99);
    final target = _clampIndex(projected);
    _target = target;
    _springTo(target.toDouble(), AppSpring.momentum, v);
    if (target != widget.index) widget.onSelect(target); // haptics already fired per detent
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final solid = MediaQuery.of(context).highContrast;
    final safe = MediaQuery.of(context).padding.bottom;
    final reduce = reduceMotion(context);

    return LayoutBuilder(
      builder: (context, c) {
        final width = math.min(c.maxWidth - 32, 76.0 * _n);
        _cell = width / _n;
        final pill = Container(
          width: width,
          height: ScrubberTabBar.height,
          decoration: BoxDecoration(
            color: solid ? cs.surface : cs.surface.withValues(alpha: dark ? 0.6 : 0.72),
            borderRadius: BorderRadius.circular(ScrubberTabBar.height / 2),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: solid ? 1 : 0.55), width: 0.5),
          ),
          child: Stack(
            children: [
              // The capsule: position comes from the spring; a GPU transform, never a layout change.
              AnimatedBuilder(
                animation: _x,
                builder: (context, _) => Transform.translate(
                  offset: Offset(_x.value * _cell, 0),
                  child: SizedBox(
                    width: _cell,
                    height: ScrubberTabBar.height,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(ScrubberTabBar.height / 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < _n; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == widget.index,
                        label: widget.tabs[i].label,
                        onTap: () => selectTab(widget.index, i, widget.onSelect),
                        child: ExcludeSemantics(
                          child: AnimatedBuilder(
                            animation: _x,
                            builder: (context, _) {
                              final near = 1.0 - (_x.value - i).abs().clamp(0.0, 1.0).toDouble();
                              return Center(
                                child: Transform.scale(
                                  scale: reduce ? 1 : 1 + 0.12 * near,
                                  child: Icon(
                                    near > 0.5 ? widget.tabs[i].selectedIcon : widget.tabs[i].icon,
                                    size: 26,
                                    color: Color.lerp(cs.onSurfaceVariant, cs.primary, near),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );

        final shadowed = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ScrubberTabBar.height / 2),
            // A bigger floating surface reads as thicker: deeper, softer shadow.
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.45 : 0.16),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ScrubberTabBar.height / 2),
            child: solid
                ? pill
                : BackdropFilter(filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22), child: pill),
          ),
        );

        return Padding(
          padding: EdgeInsets.only(bottom: safe + ScrubberTabBar.bottomGap),
          child: Center(
            child: SizedBox(
              width: width,
              height: ScrubberTabBar.height,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _onTapUp,
                onHorizontalDragStart: _onDragStart,
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: shadowed,
              ),
            ),
          ),
        );
      },
    );
  }
}
