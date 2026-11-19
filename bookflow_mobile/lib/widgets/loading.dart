import 'package:flutter/material.dart';

import '../theme.dart';
import 'motion.dart';

/// Which placeholder layout to show while a screen loads.
enum SkeletonKind { cards, rows, stats, detail }

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 8});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.border,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Gently pulses everything inside [child] (opacity 55% <-> 100%, 1.2 s cycle).
/// Opacity is composited on the GPU, so it stays smooth while the CPU is busy loading.
/// Static when reduced motion is on.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});
  final Widget child;
  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.55,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !reduceMotion(context)) {
      _started = true;
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      reduceMotion(context) ? widget.child : FadeTransition(opacity: _opacity, child: widget.child);
}

/// Reusable loading placeholder used by every data screen (via FutureView).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.kind = SkeletonKind.rows});
  final SkeletonKind kind;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = switch (kind) {
      SkeletonKind.cards => [for (var i = 0; i < 3; i++) const _CardSkeleton()],
      SkeletonKind.rows => [for (var i = 0; i < 7; i++) const _RowSkeleton()],
      SkeletonKind.stats => [for (var i = 0; i < 3; i++) const _StatRowSkeleton()],
      SkeletonKind.detail => const [
        SkeletonBox(height: 230, radius: 18),
        SizedBox(height: 16),
        SkeletonBox(width: 220, height: 24),
        SizedBox(height: 10),
        SkeletonBox(width: 160, height: 14),
        SizedBox(height: 24),
        SkeletonBox(height: 14),
        SizedBox(height: 8),
        SkeletonBox(height: 14),
        SizedBox(height: 8),
        SkeletonBox(width: 240, height: 14),
        SizedBox(height: 24),
        SkeletonBox(height: 72, radius: 16),
        SizedBox(height: 12),
        SkeletonBox(height: 72, radius: 16),
      ],
    };
    return Semantics(
      label: 'Loading',
      liveRegion: true,
      child: SkeletonPulse(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: items,
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(height: 170, radius: 18),
        SizedBox(height: 12),
        SkeletonBox(width: 200, height: 16),
        SizedBox(height: 8),
        SkeletonBox(width: 130, height: 12),
      ],
    ),
  );
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        SkeletonBox(width: 56, height: 56, radius: 14),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [SkeletonBox(height: 14), SizedBox(height: 8), SkeletonBox(width: 140, height: 12)],
          ),
        ),
      ],
    ),
  );
}

class _StatRowSkeleton extends StatelessWidget {
  const _StatRowSkeleton();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(child: SkeletonBox(height: 104, radius: 18)),
        SizedBox(width: 12),
        Expanded(child: SkeletonBox(height: 104, radius: 18)),
      ],
    ),
  );
}

/// Branded full-screen loader (used while the signed-in profile loads): the "B" mark breathes
/// gently inside a soft accent glow, with a thin progress line underneath.
class FullScreenLoader extends StatefulWidget {
  const FullScreenLoader({super.key});
  @override
  State<FullScreenLoader> createState() => _FullScreenLoaderState();
}

class _FullScreenLoaderState extends State<FullScreenLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !reduceMotion(context)) {
      _started = true;
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final v = Curves.easeInOut.transform(_c.value);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 190,
                  height: 190,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [cs.primary.withValues(alpha: 0.10 + 0.16 * v), cs.primary.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.94 + 0.06 * v,
                        child: Image.asset('assets/images/bookflow_mark.png', width: 92, filterQuality: FilterQuality.high),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 96,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(minHeight: 3, color: cs.primary, backgroundColor: cs.outline),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
