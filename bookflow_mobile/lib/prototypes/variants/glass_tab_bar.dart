import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../widgets/motion.dart';
import '../tab_bar_spec.dart';

/// "Glass": a translucent full-width bar. Content scrolls underneath it, a bright hairline marks the
/// top edge, and the selected icon pops with a tiny scale. Falls back to a solid bar when the user
/// asks for higher contrast (Apple's "reduce transparency" intent).
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, required this.tabs, required this.index, required this.onSelect});
  final List<TabSpec> tabs;
  final int index;
  final TabSelected onSelect;

  static const double height = 58;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final solid = MediaQuery.of(context).highContrast;
    final safe = MediaQuery.of(context).padding.bottom;

    final bar = Container(
      height: height + safe,
      padding: EdgeInsets.only(bottom: safe),
      decoration: BoxDecoration(
        color: solid ? cs.surface : cs.surface.withValues(alpha: dark ? 0.62 : 0.74),
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: solid ? 1 : 0.5), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: _GlassItem(
                tab: tabs[i],
                selected: i == index,
                onTap: () => selectTab(index, i, onSelect),
              ),
            ),
        ],
      ),
    );
    return solid
        ? bar
        : ClipRect(
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22), child: bar),
          );
  }
}

class _GlassItem extends StatelessWidget {
  const _GlassItem({required this.tab, required this.selected, required this.onTap});
  final TabSpec tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      child: ExcludeSemantics(
        child: Pressable(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: (selected && !reduceMotion(context)) ? 1.08 : 1,
                  duration: AppMotion.fade,
                  curve: AppMotion.outStrong,
                  child: Icon(selected ? tab.selectedIcon : tab.icon, size: 26, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
