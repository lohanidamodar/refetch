import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_message.dart';
import '../../../core/push/push_providers.dart';
import '../../../core/push/push_topic.dart';

/// Per-topic notification toggles. Each switch subscribes/unsubscribes the
/// device's push target to the Appwrite Messaging topic (client-side).
///
/// Renders nothing until topic ids are configured in AppConfig.
class NotificationSettings extends ConsumerStatefulWidget {
  const NotificationSettings({super.key});

  @override
  ConsumerState<NotificationSettings> createState() =>
      _NotificationSettingsState();
}

class _NotificationSettingsState extends ConsumerState<NotificationSettings> {
  final Map<PushTopic, bool> _enabled = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = ref.read(pushPreferencesProvider);
    for (final topic in PushTopic.configured) {
      _enabled[topic] = await prefs.isEnabled(topic);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(PushTopic topic, bool value) async {
    setState(() => _enabled[topic] = value);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (value) {
        await ref.read(pushNotificationServiceProvider).requestPermission();
      }
      await ref.read(topicSubscriptionsProvider).setEnabled(topic, value);
    } catch (error) {
      if (mounted) setState(() => _enabled[topic] = !value);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            messageForError(error, fallback: 'Could not update subscription.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topics = PushTopic.configured;
    if (topics.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          for (final topic in topics)
            SwitchListTile(
              title: Text(topic.label),
              subtitle: Text(topic.description),
              value: _enabled[topic] ?? true,
              onChanged: (value) => _toggle(topic, value),
            ),
      ],
    );
  }
}
