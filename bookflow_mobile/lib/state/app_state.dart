import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';
import '../cache.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/palette_scope.dart';

enum LoadStatus { idle, loading, ready, error }

/// Which "side" of the app the user is looking at.
enum AppMode { customer, provider, admin }

class AppState extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  BFThemeId themeId = BFThemeId.crimson;
  bool showNotificationPopup = true;
  AppUser? me;
  LoadStatus status = LoadStatus.idle;
  String? error;
  AppMode mode = AppMode.customer;
  Future<void> Function()? onSignOut;

  List<AppMode> get availableModes {
    final u = me;
    if (u == null) return const [AppMode.customer];
    return [
      AppMode.customer,
      if (u.providerProfile != null && (u.role == 'PROVIDER' || u.role == 'ADMIN')) AppMode.provider,
      if (u.isAdmin) AppMode.admin,
    ];
  }

  Future<void> loadPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      themeMode = switch (p.getString('theme')) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      final saved = p.getString('theme_id');
      themeId = BFThemeId.values.firstWhere((t) => t.name == saved, orElse: () => BFThemeId.crimson);
      showNotificationPopup = p.getBool('show_notification_popup') ?? true;
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode m) async {
    if (m == themeMode) return;
    await PaletteScope.captureSnapshot(); // lets the change cross-fade instead of snapping
    themeMode = m;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('theme', m.name);
    } catch (_) {}
  }

  Future<void> setThemeId(BFThemeId id) async {
    if (id == themeId) return;
    await PaletteScope.captureSnapshot();
    themeId = id;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('theme_id', id.name);
    } catch (_) {}
  }

  Future<void> setShowNotificationPopup(bool v) async {
    showNotificationPopup = v;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('show_notification_popup', v);
    } catch (_) {}
  }

  Future<void> loadMe(Api api, {bool silent = false}) async {
    if (!silent) {
      status = LoadStatus.loading;
      error = null;
      notifyListeners();
    }
    try {
      me = await api.me();
      if (!availableModes.contains(mode)) mode = AppMode.customer;
      status = LoadStatus.ready;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('401') || msg.contains('unauthorized')) {
        await signOut();
        return;
      }
      if (!silent || me == null) {
        error = e.toString();
        status = LoadStatus.error;
      }
    }
    notifyListeners();
  }

  void setMode(AppMode m) {
    if (!availableModes.contains(m)) return;
    mode = m;
    notifyListeners();
  }

  Future<void> signOut() async {
    DataCache.clear();
    me = null;
    status = LoadStatus.idle;
    mode = AppMode.customer;
    notifyListeners();
    try {
      await onSignOut?.call();
    } catch (_) {}
  }
}
