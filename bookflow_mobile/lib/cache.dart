/// Tiny in-memory cache used for stale-while-revalidate: screens show the last
/// known data instantly, then refresh it in the background.
class DataCache {
  static final Map<String, Object> _store = {};

  static T? get<T>(String key) {
    final v = _store[key];
    return v is T ? v : null;
  }

  static void put(String key, Object value) => _store[key] = value;

  /// Called on sign-out so one user's data is never shown to the next.
  static void clear() => _store.clear();
}
