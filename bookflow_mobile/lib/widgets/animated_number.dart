import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import 'motion.dart';

/// Counts smoothly from the previous value to a new one (300 ms, strong ease-out).
/// The first value is shown immediately; only later changes animate.
/// Digits use tabular figures so the text does not jitter while counting.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({super.key, required this.value, required this.format, this.style});
  final num value;
  final String Function(num) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final v = value.toDouble();
    final base = style ?? DefaultTextStyle.of(context).style;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: v, end: v),
      duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 300),
      curve: AppMotion.outStrong,
      builder: (context, current, _) =>
          Text(format(current), style: base.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
    );
  }
}
