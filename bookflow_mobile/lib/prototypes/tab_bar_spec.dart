import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One destination in the tab bar.
class TabSpec {
  const TabSpec(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon, selectedIcon;
}

typedef TabSelected = void Function(int index);

/// Shared by every variant: haptic on the same frame as the visual change, then notify.
void selectTab(int current, int next, TabSelected onSelect) {
  if (next != current) HapticFeedback.selectionClick();
  onSelect(next);
}
