import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../cache.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../customer/explore_screen.dart';
import '../sign_in_screen.dart';
import '../splash_screen.dart';

class _Slide {
  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.orbit,
    this.color,
  });
  final IconData icon;
  final String title, subtitle, body;
  final List<IconData> orbit;

  /// null = use the active theme's accent.
  final Color? color;

  Color get tint => color ?? AppColors.accent;
}

const _slides = [
  _Slide(
    icon: Icons.confirmation_number_outlined,
    title: 'BookFlow Marketplace',
    subtitle: 'DISCOVER & CELEBRATE',
    body: 'Browse premier event venues, photographers, caterers and live performers, curated for every celebration.',
    orbit: [Icons.apartment_rounded, Icons.photo_camera_outlined, Icons.restaurant_outlined, Icons.music_note_rounded],
  ),
  _Slide(
    icon: Icons.calendar_today_rounded,
    title: 'Seamless Reservations',
    subtitle: 'INSTANT SCHEDULING',
    body:
        'Select your event date, review transparent pricing packages and request bookings directly from certified providers.',
    orbit: [Icons.event_available_rounded, Icons.payments_outlined, Icons.verified_outlined],
    color: Color(0xFF3B82F6),
  ),
  _Slide(
    icon: Icons.forum_outlined,
    title: 'Direct Messaging',
    subtitle: 'REAL-TIME COMMUNICATION',
    body: 'Chat directly with event organizers and venue owners, receive immediate status updates and confirm details.',
    orbit: [Icons.chat_bubble_outline_rounded, Icons.notifications_none_rounded, Icons.done_all_rounded],
    color: Color(0xFF22C55E),
  ),
  _Slide(
    icon: Icons.storefront_outlined,
    title: 'List & Grow',
    subtitle: 'FOR EVENT PROVIDERS',
    body:
        'Showcase your venue or event services to thousands of customers across Zambia and manage bookings effortlessly.',
    orbit: [Icons.trending_up_rounded, Icons.star_rounded, Icons.groups_2_outlined],
    color: Color(0xFFEAB308),
  ),
];

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});
  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  final _controller = PageController();
  int _page = 0;

  /// Endless 0..1 loop that drives every ambient movement (orbits, rings, floating, background).
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(seconds: 12));

  /// One-shot entrance, started once the splash has left the screen.
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  bool _motionInit = false;

  @override
  void initState() {
    super.initState();
    context.read<Api>().searchListings().then((r) => DataCache.put('explore:all', r)).catchError((_) {});
    if (SplashGate.finished.value) {
      _enter.forward();
    } else {
      SplashGate.finished.addListener(_onSplashDone);
    }
  }

  void _onSplashDone() {
    if (SplashGate.finished.value && mounted) _enter.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionInit) return;
    _motionInit = true;
    if (reduceMotion(context)) {
      _enter.value = 1;
    } else {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    SplashGate.finished.removeListener(_onSplashDone);
    _controller.dispose();
    _clock.dispose();
    _enter.dispose();
    super.dispose();
  }

  bool get _last => _page == _slides.length - 1;

  void _next() {
    final current = _controller.hasClients ? (_controller.page ?? _page.toDouble()).round() : _page;
    if (current >= _slides.length - 1) {
      requireSignIn(context);
    } else if (reduceMotion(context)) {
      _controller.jumpToPage(current + 1);
    } else {
      _controller.animateToPage(
        current + 1,
        duration: const Duration(milliseconds: 420),
        curve: AppMotion.outStrong,
      );
    }
  }

  void _browse() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen(guest: true)));

  /// Fades + rises a block during the entrance. [a]..[b] is its slice of the 0..1 entrance timeline.
  Widget _stagger(double a, double b, Widget child, {double dy = 22}) {
    return AnimatedBuilder(
      animation: _enter,
      child: child,
      builder: (context, child) {
        final v = Interval(a, b, curve: AppMotion.outStrong).transform(_enter.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * dy), child: child),
        );
      },
    );
  }

  Color _tintAt(double page) {
    final i = page.floor().clamp(0, _slides.length - 1);
    final j = (i + 1).clamp(0, _slides.length - 1);
    return Color.lerp(_slides[i].tint, _slides[j].tint, page - i)!;
  }

  double get _pageValue =>
      (_controller.hasClients && _controller.position.haveDimensions) ? (_controller.page ?? 0.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Drifting colour blobs that follow the current slide's tint.
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([_clock, _controller]),
                builder: (context, _) => CustomPaint(
                  painter: _AmbientPainter(
                    t: _clock.value,
                    page: _pageValue,
                    tint: _tintAt(_pageValue),
                    accent: AppColors.accent,
                    isDark: AppColors.isDark,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _stagger(0.0, 0.45, _header(context), dy: -14),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => _SlideView(
                      slide: _slides[i],
                      controller: _controller,
                      index: i,
                      clock: _clock,
                      enter: _enter,
                    ),
                  ),
                ),
                _stagger(
                  0.55,
                  0.95,
                  Column(
                    children: [
                      PageDots(
                        controller: _controller,
                        count: _slides.length,
                        activeColor: AppColors.accent,
                        inactiveColor: AppColors.border,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
                        child: Column(
                          children: [
                            _Cta(onPressed: _next, label: _last ? 'Get Started' : 'Next'),
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: _browse,
                              child: Text(
                                'Browse as Guest  →',
                                style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 16, 0),
      child: Row(
        children: [
          Image.asset('assets/images/bookflow_mark.png', height: 38, filterQuality: FilterQuality.high),
          const SizedBox(width: 10),
          Text(
            'BookFlow',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.text,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Pressable(
            child: Material(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: StadiumBorder(side: BorderSide(color: AppColors.accent.withValues(alpha: 0.35))),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => requireSignIn(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  child: Text(
                    'Sign In',
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.accent, fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary call-to-action: accent gradient, soft glow, springy press, label cross-fade.
class _Cta extends StatelessWidget {
  const _Cta({required this.onPressed, required this.label});
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: [AppColors.accent, AppColors.accentDeep]),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: AppColors.isDark ? 0.35 : 0.30),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 17),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      label,
                      key: ValueKey(label),
                      style: TextStyle(
                        color: AppColors.onAccent,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: AppColors.onAccent, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.controller,
    required this.index,
    required this.clock,
    required this.enter,
  });
  final _Slide slide;
  final PageController controller;
  final int index;
  final Animation<double> clock;
  final Animation<double> enter;

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotion(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: LayoutBuilder(
        builder: (context, box) {
          final size = (box.maxHeight * 0.46).clamp(150.0, 250.0).toDouble();
          return AnimatedBuilder(
            animation: Listenable.merge([controller, enter]),
            builder: (context, _) {
              var page = index.toDouble();
              if (controller.hasClients && controller.position.haveDimensions) page = controller.page ?? page;
              final d = (page - index).clamp(-1.0, 1.0).toDouble(); // -1..1, 0 = this slide is centred
              final t = 1.0 - d.abs();
              final entrance = index == 0 ? Interval(0.1, 0.7, curve: Curves.easeOutBack).transform(enter.value) : 1.0;
              final textIn = index == 0 ? Interval(0.3, 0.8, curve: AppMotion.outStrong).transform(enter.value) : 1.0;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: (t * (entrance.clamp(0.0, 1.0))).clamp(0.0, 1.0).toDouble(),
                    child: Transform.translate(
                      offset: reduce ? Offset.zero : Offset(-d * 90, 0),
                      child: Transform.scale(
                        scale: reduce ? 1 : (0.82 + 0.18 * t) * (0.7 + 0.3 * entrance),
                        child: RepaintBoundary(
                          child: _Illustration(slide: slide, size: size, clock: clock, animate: !reduce),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size < 190 ? 20 : 34),
                  Opacity(
                    opacity: (t * textIn).clamp(0.0, 1.0).toDouble(),
                    child: Transform.translate(
                      offset: reduce ? Offset.zero : Offset(-d * 50, (1 - textIn) * 18),
                      child: _TextBlock(slide: slide),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final tint = slide.tint;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tint.withValues(alpha: 0.30)),
          ),
          child: Text(
            slide.subtitle,
            style: TextStyle(color: tint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          slide.body,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.5),
        ),
      ],
    );
  }
}

/// Floating glass card with pulsing rings and small icons orbiting around it.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.slide, required this.size, required this.clock, required this.animate});
  final _Slide slide;
  final double size;
  final Animation<double> clock;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final tint = slide.tint;
    final card = size * 0.52;
    final orbitR = size * 0.42;
    final chip = size * 0.19;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: clock,
        builder: (context, _) {
          final v = animate ? clock.value : 0.0;
          final twoPi = math.pi * 2;
          final float = math.sin(v * twoPi * 2) * 6;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Three expanding rings, evenly spaced in time.
              for (var k = 0; k < 3; k++)
                Builder(
                  builder: (context) {
                    final ph = animate ? (v * 3 + k / 3) % 1.0 : 0.3 + k * 0.3;
                    return Opacity(
                      opacity: ((1 - ph) * 0.55).clamp(0.0, 1.0).toDouble(),
                      child: Container(
                        width: size * (0.55 + 0.45 * ph),
                        height: size * (0.55 + 0.45 * ph),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: tint.withValues(alpha: 0.55), width: 1.4),
                        ),
                      ),
                    );
                  },
                ),
              // Glow
              Container(
                width: size * 0.8,
                height: size * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [tint.withValues(alpha: AppColors.isDark ? 0.26 : 0.18), tint.withValues(alpha: 0)],
                  ),
                ),
              ),
              // Orbiting chips
              for (var i = 0; i < slide.orbit.length; i++)
                Builder(
                  builder: (context) {
                    final a = twoPi * (v + i / slide.orbit.length) - math.pi / 2;
                    final bob = math.sin(twoPi * (v * 2 + i * 0.37)) * 3;
                    return Transform.translate(
                      offset: Offset(math.cos(a) * orbitR, math.sin(a) * orbitR + bob),
                      child: Container(
                        width: chip,
                        height: chip,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          border: Border.all(color: tint.withValues(alpha: 0.45)),
                          boxShadow: [
                            BoxShadow(color: tint.withValues(alpha: 0.22), blurRadius: 14, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Icon(slide.orbit[i], size: chip * 0.5, color: tint),
                      ),
                    );
                  },
                ),
              // Centre card
              Transform.translate(
                offset: Offset(0, float),
                child: Transform.rotate(
                  angle: math.sin(v * twoPi) * 0.035,
                  child: Container(
                    width: card,
                    height: card,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(card * 0.3),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.surface, AppColors.surfaceAlt],
                      ),
                      border: Border.all(color: tint.withValues(alpha: 0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: tint.withValues(alpha: 0.30), blurRadius: 34, offset: const Offset(0, 14)),
                      ],
                    ),
                    child: Icon(slide.icon, size: card * 0.46, color: tint),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({
    required this.t,
    required this.page,
    required this.tint,
    required this.accent,
    required this.isDark,
  });
  final double t, page;
  final Color tint, accent;
  final bool isDark;

  void _blob(Canvas canvas, Offset c, double r, Color color, double alpha) {
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final a = t * math.pi * 2;
    final k = isDark ? 1.0 : 0.7;
    _blob(canvas, Offset(w * 0.10 + math.sin(a) * w * 0.08 - page * 22, h * 0.16 + math.cos(a) * h * 0.03), w * 0.85, tint, 0.30 * k);
    _blob(canvas, Offset(w * 1.00 + math.cos(a) * w * 0.06 - page * 36, h * 0.58 + math.sin(a) * h * 0.04), w * 0.75, accent, 0.20 * k);
    _blob(canvas, Offset(w * 0.30 + math.sin(a + 2) * w * 0.07 - page * 14, h * 1.02 + math.cos(a) * h * 0.02), w * 0.80, tint, 0.18 * k);
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter old) =>
      old.t != t || old.page != page || old.tint != tint || old.accent != accent || old.isDark != isDark;
}
