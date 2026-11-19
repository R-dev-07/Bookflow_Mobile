import 'dart:async';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../auth/clerk_bridge.dart';
import '../cache.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'customer/explore_screen.dart';
import 'landing/landing_screen.dart';
import 'shared/notifications_screen.dart';
import 'shells.dart';

/// Shown once Clerk says the user is signed in: loads the BookFlow profile (role) then shows the right app.
class SignedInRoot extends StatefulWidget {
  const SignedInRoot({super.key, required this.auth});
  final ClerkAuthState auth;
  @override
  State<SignedInRoot> createState() => _SignedInRootState();
}

class _SignedInRootState extends State<SignedInRoot> {
  late final Api _api = context.read<Api>();
  late final AppState _state = context.read<AppState>();

  @override
  void initState() {
    super.initState();
    _bind();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _state.loadMe(_api);
      if (_state.showNotificationPopup && mounted) {
        try {
          final notifs = await _api.notifications();
          if (notifs.unread > 0 && mounted) {
            showDialog(
              context: context,
              builder: (c) => AlertDialog(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.border),
                ),
                title: Text('Notifications', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
                content: Text(
                  'You have ${notifs.unread} unread notification${notifs.unread == 1 ? '' : 's'}.',
                  style: TextStyle(color: AppColors.muted),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: Text('Dismiss', style: TextStyle(color: AppColors.muted)),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(c);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                    child: const Text('View'),
                  ),
                ],
              ),
            );
          }
        } catch (_) {}
      }
    });
    // Fetch the first page of listings in parallel with the profile so Explore opens instantly.
    unawaited(_api.searchListings().then((r) => DataCache.put('explore:all', r)).catchError((_) {}));
  }

  void _bind() {
    _api.tokenProvider = () => clerkToken(widget.auth);
    _state.onSignOut = () => clerkSignOut(widget.auth);
  }

  @override
  void didUpdateWidget(covariant SignedInRoot old) {
    super.didUpdateWidget(old);
    if (old.auth != widget.auth) _bind();
  }

  @override
  void dispose() {
    _api.tokenProvider = null;
    _state.onSignOut = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    switch (s.status) {
      case LoadStatus.ready:
        return const RoleShell();
      case LoadStatus.error:
        return Scaffold(
          body: SafeArea(
            child: ErrorView(
              message: s.error ?? 'Could not load your profile',
              onRetry: () => s.loadMe(_api),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: s.signOut,
                child: const Text('Sign out'),
              ),
            ),
          ),
        );
      default:
        return const FullScreenLoader();
    }
  }
}
