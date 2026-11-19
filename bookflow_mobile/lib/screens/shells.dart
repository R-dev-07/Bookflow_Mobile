import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/motion.dart';
import 'admin/admin_screens.dart';
import 'customer/bookings_screen.dart';
import 'customer/compare_list_screen.dart';
import 'customer/explore_screen.dart';
import 'provider/provider_dashboard.dart';
import 'provider/provider_listings.dart';
import 'provider/provider_requests.dart';
import 'shared/account_screen.dart';
import 'shared/messages_screens.dart';

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon, this.builder);
  final String label;
  final IconData icon, selectedIcon;
  final Widget Function() builder;
}

/// Picks the navigation shell for the active [AppMode].
class RoleShell extends StatelessWidget {
  const RoleShell({super.key});
  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppState, AppMode>((s) => s.mode);
    switch (mode) {
      case AppMode.provider:
        return const _TabShell(
          key: ValueKey('provider'),
          tabs: [
            _Tab('Dashboard', Icons.space_dashboard_outlined, Icons.space_dashboard, ProviderDashboard.new),
            _Tab('Listings', Icons.storefront_outlined, Icons.storefront, ProviderListingsScreen.new),
            _Tab('Requests', Icons.inbox_outlined, Icons.inbox, ProviderRequestsScreen.new),
            _Tab('Messages', Icons.chat_bubble_outline, Icons.chat_bubble, ConversationsScreen.new),
            _Tab('Account', Icons.person_outline, Icons.person, AccountScreen.new),
          ],
        );
      case AppMode.admin:
        return const _TabShell(
          key: ValueKey('admin'),
          tabs: [
            _Tab('Overview', Icons.insights_outlined, Icons.insights, AdminOverviewScreen.new),
            _Tab('Moderation', Icons.fact_check_outlined, Icons.fact_check, AdminModerationScreen.new),
            _Tab('Users', Icons.group_outlined, Icons.group, AdminUsersScreen.new),
            _Tab('Account', Icons.person_outline, Icons.person, AccountScreen.new),
          ],
        );
      case AppMode.customer:
        return const _TabShell(
          key: ValueKey('customer'),
          tabs: [
            _Tab('Explore', Icons.explore_outlined, Icons.explore, ExploreScreen.new),
            _Tab('Compare', Icons.compare_arrows_outlined, Icons.compare_arrows, CompareListScreen.new),
            _Tab('Bookings', Icons.event_note_outlined, Icons.event_note, BookingsScreen.new),
            _Tab('Messages', Icons.chat_bubble_outline, Icons.chat_bubble, ConversationsScreen.new),
            _Tab('Account', Icons.person_outline, Icons.person, AccountScreen.new),
          ],
        );
    }
  }
}

class _TabShell extends StatefulWidget {
  const _TabShell({super.key, required this.tabs});
  final List<_Tab> tabs;
  @override
  State<_TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<_TabShell> {
  int _index = 0;

  void _select(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tabs[_index];
    final reduce = reduceMotion(context);
    return Scaffold(
      extendBody: true,
      // Fade-through between tabs (a short fade + tiny scale), instead of an abrupt swap.
      body: AnimatedSwitcher(
        duration: reduce ? AppMotion.reducedFade : const Duration(milliseconds: 240),
        switchInCurve: AppMotion.outStrong,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) =>
            Stack(fit: StackFit.expand, children: [...previous, if (current != null) current]),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: reduce
              ? child
              : ScaleTransition(scale: Tween<double>(begin: 0.985, end: 1).animate(anim), child: child),
        ),
        child: KeyedSubtree(key: ValueKey('${tab.label}-$_index'), child: tab.builder()),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: AppColors.isDark ? 0.45 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth / widget.tabs.length;
              return SizedBox(
                height: 58,
                child: Stack(
                  children: [
                    // Sliding highlight pill that glides to the selected tab.
                    AnimatedPositioned(
                      duration: reduce ? Duration.zero : const Duration(milliseconds: 320),
                      curve: Curves.fastOutSlowIn,
                      left: w * _index,
                      top: 0,
                      bottom: 0,
                      width: w,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < widget.tabs.length; i++) Expanded(child: _buildNavItem(i, widget.tabs[i])),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _Tab t) {
    final selected = _index == index;
    final color = selected ? AppColors.accent : AppColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: t.label,
      child: InkWell(
        onTap: () => _select(index),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: Icon(
                  selected ? t.selectedIcon : t.icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  t.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
