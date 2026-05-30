import 'package:shared_preferences/shared_preferences.dart';

/// Persists the Appwrite push-target id so it survives restarts and can be
/// updated (on token refresh) or deleted (on sign-out).
abstract class PushTargetStore {
  Future<String?> read();
  Future<void> write(String targetId);
  Future<void> clear();
}

/// [PushTargetStore] backed by `shared_preferences`.
class PrefsPushTargetStore implements PushTargetStore {
  static const _key = 'refetch_push_target_id';

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<void> write(String targetId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, targetId);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// In-memory store, useful for tests.
class InMemoryPushTargetStore implements PushTargetStore {
  String? _value;

  InMemoryPushTargetStore([this._value]);

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String targetId) async => _value = targetId;

  @override
  Future<void> clear() async => _value = null;
}
