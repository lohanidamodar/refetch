import 'package:appwrite/appwrite.dart';

import 'push_target_store.dart';
import 'push_topic.dart';

/// Subscribes/unsubscribes the device's push target to Appwrite Messaging topics
/// using the **client** `Messaging.createSubscriber` / `deleteSubscriber` APIs —
/// no backend function required.
///
/// The subscriber id is the target id, which makes subscribe/unsubscribe
/// deterministic and idempotent (one target subscribes a topic at most once).
class TopicSubscriptions {
  TopicSubscriptions(this._messaging, this._targetStore, this._prefs);

  final Messaging _messaging;
  final PushTargetStore _targetStore;
  final PushPreferences _prefs;

  /// Persists the choice and applies it immediately if a target exists; if not,
  /// it is applied on the next registration via [syncOnRegister].
  Future<void> setEnabled(PushTopic topic, bool enabled) async {
    await _prefs.setEnabled(topic, enabled);
    if (!topic.isConfigured) return;
    final targetId = await _targetStore.read();
    if (targetId == null) return;
    if (enabled) {
      await _subscribe(topic.topicId, targetId);
    } else {
      await _unsubscribe(topic.topicId, targetId);
    }
  }

  /// Applies saved preferences to a freshly-registered [targetId]. Best-effort:
  /// a failure on one topic does not block the others.
  Future<void> syncOnRegister(String targetId) async {
    for (final topic in PushTopic.configured) {
      try {
        if (await _prefs.isEnabled(topic)) {
          await _subscribe(topic.topicId, targetId);
        }
      } catch (_) {
        // Best-effort; the user can re-toggle from settings.
      }
    }
  }

  Future<void> _subscribe(String topicId, String targetId) async {
    try {
      await _messaging.createSubscriber(
        topicId: topicId,
        subscriberId: targetId,
        targetId: targetId,
      );
    } on AppwriteException catch (e) {
      if (e.code != 409) rethrow; // 409 = already subscribed
    }
  }

  Future<void> _unsubscribe(String topicId, String targetId) async {
    try {
      await _messaging.deleteSubscriber(
        topicId: topicId,
        subscriberId: targetId,
      );
    } on AppwriteException catch (e) {
      if (e.code != 404) rethrow; // 404 = not subscribed
    }
  }
}
