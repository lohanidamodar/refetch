import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// The notification topics a user can opt in/out of. Topic ids come from
/// [AppConfig]; a topic with an empty id is "not configured" and is hidden /
/// skipped.
enum PushTopic {
  digest('Daily digest', 'Top stories once a day'),
  replies('Replies', 'When someone replies to your post or comment');

  const PushTopic(this.label, this.description);

  final String label;
  final String description;

  String get topicId => switch (this) {
    PushTopic.digest => AppConfig.digestTopicId,
    PushTopic.replies => AppConfig.repliesTopicId,
  };

  bool get isConfigured => topicId.isNotEmpty;

  String get prefKey => 'push_topic_${name}_enabled';

  /// Topics that have a configured id (shown in settings, synced on register).
  static List<PushTopic> get configured =>
      values.where((t) => t.isConfigured).toList(growable: false);
}

/// Persists the user's per-topic opt-in choices. Topics default to enabled.
class PushPreferences {
  Future<bool> isEnabled(PushTopic topic) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(topic.prefKey) ?? true;
  }

  Future<void> setEnabled(PushTopic topic, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(topic.prefKey, enabled);
  }
}
