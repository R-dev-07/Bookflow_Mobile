import 'dart:async';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api.dart';
import 'config.dart';
import 'screens/customer/explore_screen.dart';
import 'screens/gate.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'widgets/palette_scope.dart';

Future<void> main() async {
  // Last line of defence: log uncaught async errors instead of crashing silently.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (kReleaseMode) {
      // Friendly replacement for the grey "red screen" if a widget ever fails to build.
      ErrorWidget.builder = (details) => const Material(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Something went wrong displaying this section.\nPlease go back and try again.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final state = AppState();
    await state.loadPrefs();
    runApp(BookFlowApp(state: state, api: Api(AppConfig.apiBaseUrl)));
  }, (error, stack) => debugPrint('Unhandled error: $error\n$stack'));
}

class BookFlowApp extends StatelessWidget {
  const BookFlowApp({super.key, required this.state, required this.api});
  final AppState state;
  final Api api;

  @override
  Widget build(BuildContext context) {
    if (AppConfig.clerkKey.isEmpty) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        home: const Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Missing Clerk key.\n\nRun with:\nflutter run --dart-define=CLERK_PUBLISHABLE_KEY=pk_test_...',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        Provider<Api>.value(value: api),
        ChangeNotifierProvider<AppState>.value(value: state),
      ],
      child: ClerkAuth(
        config: ClerkAuthConfig(publishableKey: AppConfig.clerkKey),
        child: Consumer<AppState>(
          builder: (context, s, _) => MaterialApp(
            title: 'BookFlow',
            scrollBehavior: const AppScrollBehavior(),
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light, s.themeId),
            darkTheme: buildTheme(Brightness.dark, s.themeId),
            themeMode: s.themeMode,
            // We cross-fade theme changes ourselves (see PaletteScope), so Flutter's own
            // ThemeData tween is switched off to keep static and themed colours in sync.
            themeAnimationDuration: Duration.zero,
            builder: (context, child) => PaletteScope(
              themeId: s.themeId,
              child: child ?? const SizedBox.shrink(),
            ),
            home: SplashGate(
              child: ClerkErrorListener(
                child: ClerkAuthBuilder(
                  signedInBuilder: (context, authState) => SignedInRoot(auth: authState),
                  signedOutBuilder: (context, authState) => const ExploreScreen(guest: true),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
