import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/common.dart';
import 'compare_screen.dart';

class CompareManager {
  static final ValueNotifier<List<ListingSummary>> items = ValueNotifier<List<ListingSummary>>([]);

  static void toggle(ListingSummary l) {
    final current = List<ListingSummary>.from(items.value);
    if (current.any((c) => c.id == l.id)) {
      current.removeWhere((c) => c.id == l.id);
    } else {
      if (current.length >= 2) {
        current.removeAt(0);
      }
      current.add(l);
    }
    items.value = current;
  }

  static void clear() {
    items.value = [];
  }
}

class CompareListScreen extends StatelessWidget {
  const CompareListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Compare Venues')),
      body: ValueListenableBuilder<List<ListingSummary>>(
        valueListenable: CompareManager.items,
        builder: (context, list, _) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.compare_arrows_rounded,
              title: 'No venues selected for comparison',
              subtitle: 'Tap the "Compare" button on any venue card in Explore to add it here.',
            );
          }
          if (list.length == 1) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NetImage(list[0].image, width: double.infinity, height: 160, radius: 16),
                  const SizedBox(height: 16),
                  Text(list[0].title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.text)),
                  const SizedBox(height: 8),
                  Text('1 venue selected. Select 1 more venue from Explore to compare side-by-side.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 24),
                  BFButton(
                    onPressed: () => CompareManager.clear(),
                    label: 'Clear Selection',
                    isSecondary: true,
                  ),
                ],
              ),
            );
          }
          return CompareVenuesScreen(venueA: list[0], venueB: list[1]);
        },
      ),
    );
  }
}
