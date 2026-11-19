import 'package:flutter/foundation.dart';

/// App configuration for BookFlow.
/// Defaults to your live Render cloud backend and Clerk publishable key.
class AppConfig {
  static const clerkKey = String.fromEnvironment(
    'CLERK_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_c2FjcmVkLWxhYnJhZG9yLTgzNTguY2xlcmsuYWNjb3VudHMuZGV2JA',
  );
  static const _api = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://bookflow-mobile.onrender.com',
  );

  /// The database stores no currency, so the symbol is a display setting (e.g. Zambian Kwacha 'K').
  static const currencySymbol = 'K';

  static String get apiBaseUrl {
    if (_api.isNotEmpty) return _api.endsWith('/') ? _api.substring(0, _api.length - 1) : _api;
    return 'https://bookflow-mobile.onrender.com';
  }
}
