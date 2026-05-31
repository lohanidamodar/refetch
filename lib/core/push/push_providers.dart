import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../appwrite/appwrite_providers.dart';
import 'push_notification_service.dart';
import 'push_registrar.dart';
import 'push_target_store.dart';
import 'push_topic.dart';
import 'topic_subscriptions.dart';

final pushTargetStoreProvider = Provider<PushTargetStore>((ref) {
  return PrefsPushTargetStore();
});

final pushRegistrarProvider = Provider<PushRegistrar>((ref) {
  return PushRegistrar(
    ref.watch(accountProvider),
    ref.watch(pushTargetStoreProvider),
  );
});

final messagingProvider = Provider<Messaging>((ref) {
  return Messaging(ref.watch(appwriteClientProvider));
});

final pushPreferencesProvider = Provider<PushPreferences>((ref) {
  return PushPreferences();
});

final topicSubscriptionsProvider = Provider<TopicSubscriptions>((ref) {
  return TopicSubscriptions(
    ref.watch(messagingProvider),
    ref.watch(pushTargetStoreProvider),
    ref.watch(pushPreferencesProvider),
  );
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final service = PushNotificationService(
    ref.watch(pushRegistrarProvider),
    ref.watch(topicSubscriptionsProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
