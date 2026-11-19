import 'package:flutter/material.dart';

import 'config.dart';
import 'theme.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// 1234.5 -> "$1,234.50"
String money(num? v) {
  if (v == null) return '-';
  final neg = v < 0;
  final parts = v.abs().toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  final dec = parts[1] == '00' ? '' : '.${parts[1]}';
  return '${neg ? '-' : ''}${AppConfig.currencySymbol}$whole$dec';
}

/// Uses the fields of [d] as-is (event dates are stored as UTC calendar days).
String fmtDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';
String fmtDateLong(DateTime d) => '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}, ${d.year}';

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return fmtDate(d);
}

String fmtTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
}

String titleCase(String s) =>
    s.toLowerCase().split('_').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');

Color statusColor(BuildContext context, String status) {
  final base = switch (status.toUpperCase()) {
    'APPROVED' || 'ACTIVE' => AppColors.statusActive,
    'COMPLETED' => AppColors.statusCompleted,
    'PENDING' || 'PENDING_REVIEW' => AppColors.statusPending,
    'REJECTED' || 'CANCELLED' => AppColors.statusRejected,
    _ => AppColors.muted, // PAUSED, DRAFT, anything else
  };
  // Bright status colours wash out on a light background, so deepen them there.
  if (Theme.of(context).brightness == Brightness.light && base != AppColors.muted) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness - 0.16).clamp(0.0, 1.0).toDouble()).toColor();
  }
  return base;
}

/// 12.0 -> "12" (used by animated counters).
String formatCount(num n) => n.round().toString();
