import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../cache.dart';
import '../theme.dart';
import '../utils.dart';
import 'animated_number.dart';
import 'loading.dart';
import 'motion.dart';

export 'animated_number.dart';
export 'loading.dart';
export 'motion.dart';
export 'page_dots.dart';

void showSnack(BuildContext context, String message, {bool error = false}) {
  if (error) HapticFeedback.mediumImpact();
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: error ? Colors.white : AppColors.onAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: error ? AppColors.statusRejected : AppColors.accent,
    ),
  );
}

/// Rounded surface used for list rows and panels. Tappable cards get press feedback.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderColor,
    this.backgroundColor,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Pressable(
      enabled: onTap != null,
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: backgroundColor ?? (AppColors.surface),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor ?? (AppColors.border),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.accent).withValues(alpha: isDark ? 0.22 : 0.07),
              blurRadius: isDark ? 14 : 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        titleCase(status),
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: -0.1),
      ),
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars(this.rating, {super.key, this.size = 16});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) {
      final icon = rating >= i + 0.75
          ? Icons.star_rounded
          : (rating >= i + 0.25 ? Icons.star_half_rounded : Icons.star_outline_rounded);
      return Icon(icon, size: size, color: AppColors.accent);
    }),
  );
}

class BFButton extends StatelessWidget {
  const BFButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isSecondary = false,
    this.isFullWidth = true,
  });
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isSecondary;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Text(label),
      ],
    );

    final btn = isSecondary
        ? OutlinedButton(onPressed: onPressed, child: child)
        : FilledButton(onPressed: onPressed, child: child);

    final pressable = Pressable(enabled: onPressed != null, child: btn);
    return isFullWidth ? SizedBox(width: double.infinity, child: pressable) : pressable;
  }
}

class NetImage extends StatelessWidget {
  const NetImage(
    this.url, {
    super.key,
    this.height,
    this.width,
    this.radius = 14,
    this.icon = Icons.image_outlined,
  });
  final String? url;
  final double? height, width, radius;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholder = Container(
      height: height,
      width: width,
      color: isDark ? AppColors.surface : AppColors.border,
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.muted, size: 32),
    );
    if (url == null || url!.isEmpty) return placeholder;

    Widget imageWidget;
    if (url!.startsWith('data:image/')) {
      try {
        final commaIdx = url!.indexOf(',');
        final base64Str = commaIdx != -1 ? url!.substring(commaIdx + 1) : url!;
        final bytes = base64Decode(base64Str);
        imageWidget = Image.memory(
          bytes,
          height: height,
          width: width,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => placeholder,
        );
      } catch (_) {
        imageWidget = placeholder;
      }
    } else if (url!.startsWith('http://') || url!.startsWith('https://')) {
      imageWidget = CachedNetworkImage(
        imageUrl: url!,
        height: height,
        width: width,
        fit: BoxFit.cover,
        memCacheWidth: 900,
        fadeInDuration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 180),
        fadeOutDuration: Duration.zero,
        placeholder: (c, u) => placeholder,
        errorWidget: (c, u, e) => placeholder,
      );
    } else {
      imageWidget = Image.file(
        File(url!),
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => placeholder,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 0),
      child: imageWidget,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(4)),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: FadeSlideIn(
       child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
       ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.cloud_off_rounded,
    title: 'Something went wrong',
    subtitle: message,
    action: onRetry == null
        ? null
        : OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
  );
}

class FutureView<T> extends StatefulWidget {
  const FutureView({
    super.key,
    required this.load,
    required this.builder,
    this.cacheKey,
    this.skeleton = SkeletonKind.rows,
  });
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;
  final String? cacheKey;
  final SkeletonKind skeleton;

  @override
  State<FutureView<T>> createState() => _FutureViewState<T>();
}

class _FutureViewState<T> extends State<FutureView<T>> {
  T? _data;
  Object? _error;
  bool _loading = true;
  bool _showSkeleton = false;
  Timer? _skeletonTimer;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    if (widget.cacheKey != null) _data = DataCache.get<T>(widget.cacheKey!);
    _begin();
    _fetch();
  }

  @override
  void dispose() {
    _skeletonTimer?.cancel();
    super.dispose();
  }

  void _begin() {
    _loading = true;
    _error = null;
    if (_data == null) {
      _showSkeleton = false;
      _skeletonTimer?.cancel();
      _skeletonTimer = Timer(const Duration(milliseconds: 120), () {
        if (mounted && _data == null && _loading) setState(() => _showSkeleton = true);
      });
    }
  }

  Future<void> _fetch() async {
    final seq = ++_seq;
    try {
      final d = await widget.load();
      if (!mounted || seq != _seq) return;
      if (widget.cacheKey != null && d != null) DataCache.put(widget.cacheKey!, d as Object);
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _seq) return;
      final hadData = _data != null;
      setState(() {
        _error = hadData ? null : e;
        _loading = false;
      });
      if (hadData) showSnack(context, 'Could not refresh: $e', error: true);
    }
  }

  Future<void> _reload() {
    setState(_begin);
    return _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_data != null) {
      body = KeyedSubtree(
        key: const ValueKey('content'),
        child: widget.builder(context, _data as T, _reload),
      );
    } else if (_error != null) {
      body = ErrorView(key: const ValueKey('error'), message: _error.toString(), onRetry: _reload);
    } else if (_showSkeleton) {
      body = LoadingView(key: const ValueKey('skeleton'), kind: widget.skeleton);
    } else {
      body = const SizedBox.shrink(key: ValueKey('blank'));
    }
    return AnimatedSwitcher(
      duration: AppMotion.fadeFor(context),
      switchInCurve: AppMotion.outStrong,
      switchOutCurve: AppMotion.outStrong,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, if (current != null) current]),
      child: body,
    );
  }
}

class RefreshList extends StatelessWidget {
  const RefreshList({
    super.key,
    required this.onRefresh,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 100),
  });
  final Future<void> Function() onRefresh;
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: padding,
        children: children,
      ),
    );
  }
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message, {
  String confirmLabel = 'Confirm',
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.border),
      ),
      title: Text(title, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
      content: Text(message, style: TextStyle(color: AppColors.muted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: Text('Cancel', style: TextStyle(color: AppColors.muted)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r == true;
}

Future<String?> askText(BuildContext context, String title, {String hint = '', bool required = false}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final ctrl = TextEditingController();
  final r = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.border),
      ),
      title: Text(title, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLines: 3,
        style: TextStyle(color: AppColors.text),
        decoration: InputDecoration(
          hintText: hint,
          fillColor: AppColors.bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: Text('Cancel', style: TextStyle(color: AppColors.muted)),
        ),
        FilledButton(
          onPressed: () {
            if (required && ctrl.text.trim().isEmpty) return;
            Navigator.pop(c, ctrl.text.trim());
          },
          child: const Text('Submit'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return r;
}

InputDecoration fieldDecoration(String label, {String? hint, Widget? prefix}) => InputDecoration(
  labelText: label,
  hintText: hint,
  prefixIcon: prefix,
);

class KeyValue extends StatelessWidget {
  const KeyValue(this.label, this.value, {super.key});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: AppColors.muted, fontSize: 14)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.text, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    this.value,
    this.amount,
    this.format,
    required this.icon,
    this.onTap,
  }) : assert(value != null || amount != null);
  final String label;
  final String? value;
  final num? amount;
  final String Function(num)? format;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.text,
      letterSpacing: -0.5,
    );
    return AppCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accent, size: 22),
          ),
          const SizedBox(height: 14),
          amount != null
              ? AnimatedNumber(value: amount!, format: format ?? formatCount, style: style)
              : Text(value!, style: style),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.tiles});
  final List<StatTile> tiles;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final w = (c.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final t in tiles) SizedBox(width: w, child: t)],
      );
    },
  );
}
