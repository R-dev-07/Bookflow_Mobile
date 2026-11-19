import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'motion.dart';

/// Sits at the top of the app (inside MaterialApp.builder) and is responsible for three things:
///
///  1. Applying the active theme + brightness to [AppColors] *before* any screen builds.
///  2. Rebuilding every screen in the same frame when that changes. Many widgets read
///     [AppColors] directly (not through `Theme.of`), so Flutter would not otherwise know they are
///     out of date. This was the root cause of the old "switching light <-> dark leaves half of the
///     app in the wrong colours" bug.
///  3. Cross-fading from the old look to the new one, so changing theme feels smooth instead of
///     snapping. Call [PaletteScope.captureSnapshot] right before you change the theme.
class PaletteScope extends StatefulWidget {
  const PaletteScope({super.key, required this.themeId, required this.child});

  final BFThemeId themeId;
  final Widget child;

  /// Freezes a picture of the current screen so the next theme change can fade from it.
  static Future<void> captureSnapshot() async => _active?._capture();

  static _PaletteScopeState? _active;

  @override
  State<PaletteScope> createState() => _PaletteScopeState();
}

class _PaletteScopeState extends State<PaletteScope> with SingleTickerProviderStateMixin {
  final GlobalKey _boundaryKey = GlobalKey();
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 0,
  );
  ui.Image? _snap;
  bool _fading = false;
  bool _first = true;

  @override
  void initState() {
    super.initState();
    PaletteScope._active = this;
    _fade.addStatusListener((s) {
      if (s == AnimationStatus.dismissed) _clearSnap();
    });
  }

  @override
  void dispose() {
    if (PaletteScope._active == this) PaletteScope._active = null;
    _fade.dispose();
    _snap?.dispose();
    super.dispose();
  }

  void _clearSnap() {
    _fading = false;
    final old = _snap;
    if (old == null) return;
    if (mounted) setState(() => _snap = null);
    old.dispose();
  }

  Future<void> _capture() async {
    if (_snap != null) return;
    try {
      final ro = _boundaryKey.currentContext?.findRenderObject();
      if (ro is! RenderRepaintBoundary) return;
      final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
      final img = await ro.toImage(pixelRatio: dpr.clamp(1.0, 2.5).toDouble());
      if (!mounted) {
        img.dispose();
        return;
      }
      _fade.value = 1;
      setState(() => _snap = img);
      // Safety net: if the theme never actually changed, don't leave the picture on screen.
      Timer(const Duration(milliseconds: 1500), () {
        if (mounted && _snap != null && !_fading) _fade.reverse(from: 1);
      });
    } catch (_) {
      // Capturing is a nicety; the theme change still happens, just without the cross-fade.
    }
  }

  void _rebuildDescendants() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final changed = AppColors.apply(widget.themeId, brightness);
    if (changed && !_first) {
      _rebuildDescendants();
      if (_snap != null && !_fading) {
        _fading = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _snap == null) return;
          if (reduceMotion(context)) {
            _fade.value = 0;
          } else {
            _fade.reverse(from: 1);
          }
        });
      }
    }
    _first = false;

    final isDark = brightness == Brightness.dark;
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(key: _boundaryKey, child: widget.child),
          if (_snap != null)
            IgnorePointer(
              child: FadeTransition(
                opacity: _fade,
                child: RawImage(image: _snap, fit: BoxFit.fill, filterQuality: FilterQuality.low),
              ),
            ),
        ],
      ),
    );
  }
}
