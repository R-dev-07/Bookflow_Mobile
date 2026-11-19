import 'package:flutter/material.dart';

import '../../widgets/motion.dart';
import '../tab_bar_spec.dart';

/// "Quiet": a solid bar for a daily-use tool. Hairline divider, labels always visible, a short
/// accent line marks the active tab. No blur, no scaling, no movement: only a quick color/opacity
/// change, so nothing competes with the content.
class QuietTabBar extends StatelessWidget {
  const QuietTabBar({super.key, required this.tabs, required this.index, required this.onSelect});
  final List<TabSpec> tabs;
  final int index;
  final TabSelected onSelect;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final safe = MediaQuery.of(context).padding.bottom;
    return Container(
      height: height + safe,
      padding: EdgeInsets.only(bottom: safe),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7))),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: _QuietItem(
                tab: tabs[i],
                selected: i == index,
                onTap: () => selectTab(index, i, onSelect),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuietItem extends StatelessWidget {
  const _QuietItem({required this.tab, required this.selected, required this.onTap});
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
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 0,
                child: AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: AppMotion.fadeFor(context) ~/ 2,
                  child: Container(
                    width: 28,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selected ? tab.selectedIcon : tab.icon, size: 24, color: color),
                  const SizedBox(height: 3),
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
