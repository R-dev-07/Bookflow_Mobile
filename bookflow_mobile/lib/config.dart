import 'package:flutter/foundation.dart';

/// Build-time configuration, passed with --dart-define:
///   flutter run --dart-define=CLERK_PUBLISHABLE_KEY=pk_test_xxx \
///               --dart-define=API_BASE_URL=http://10.0.2.2:4000
class AppConfig {
  static const clerkKey = String.fromEnvironment('CLERK_PUBLISHABLE_KEY');
  static const _api = String.fromEnvironment('API_BASE_URL');

  /// The database stores no currency, so the symbol is a display setting (e.g. Zambian Kwacha 'K').
  static const currencySymbol = 'K';

  static String get apiBaseUrl {
    if (_api.isNotEmpty) return _api.endsWith('/') ? _api.substring(0, _api.length - 1) : _api;
    if (kIsWeb) return 'http://localhost:4000';
    if (defaultTargetPlatform == TargetPlatform.android)
      return 'http://10.0.2.2:4000'; // Android emulator -> host
    return 'http://localhost:4000'; // iOS simulator
  }
}
