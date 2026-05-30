import 'package:appwrite/appwrite.dart';

import 'push_target_store.dart';

/// Registers/updates/removes the device's Appwrite push target.
///
/// This is the testable core of push handling: it depends only on the Appwrite
/// [Account] service and a [PushTargetStore], with no Firebase/platform code.
///
/// Behaviour:
///  * First registration creates a target and remembers its id.
///  * A later token (e.g. FCM refresh) updates the existing target in place.
///  * [unregister] deletes the target (on sign-out) and forgets the id.
class PushRegistrar {
  PushRegistrar(this._account, this._store);

  final Account _account;
  final PushTargetStore _store;

  /// Registers [token] as a push target for the current user, creating the
  /// target on first use (bound to [providerId], when given) and updating it
  /// thereafter. Returns the target id, or `null` if the operation failed
  /// (e.g. no session).
  Future<String?> register(String token, {String? providerId}) async {
    if (token.isEmpty) return null;
    try {
      final existing = await _store.read();
      if (existing != null) {
        final target = await _account.updatePushTarget(
          targetId: existing,
          identifier: token,
        );
        return target.$id;
      }
      final target = await _account.createPushTarget(
        targetId: ID.unique(),
        identifier: token,
        providerId: (providerId != null && providerId.isNotEmpty)
            ? providerId
            : null,
      );
      await _store.write(target.$id);
      return target.$id;
    } on AppwriteException {
      // A stale stored id (e.g. target deleted server-side) — drop it so the
      // next attempt creates a fresh target.
      await _store.clear();
      return null;
    }
  }

  /// Deletes the stored push target, if any. Safe to call when none exists.
  Future<void> unregister() async {
    final existing = await _store.read();
    if (existing == null) return;
    try {
      await _account.deletePushTarget(targetId: existing);
    } on AppwriteException {
      // Already gone — fall through and clear locally.
    }
    await _store.clear();
  }
}
