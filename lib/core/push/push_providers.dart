import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../appwrite/appwrite_providers.dart';
import '../config/app_config.dart';
import 'push_notification_service.dart';
import 'push_registrar.dart';
import 'push_target_store.dart';

final pushTargetStoreProvider = Provider<PushTargetStore>((ref) {
  return PrefsPushTargetStore();
});

final pushRegistrarProvider = Provider<PushRegistrar>((ref) {
  return PushRegistrar(
    ref.watch(accountProvider),
    ref.watch(pushTargetStoreProvider),
  );
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final service = PushNotificationService(ref.watch(pushRegistrarProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// Best-effort: subscribes the signed-in user's push targets to the app's
/// notification topics by executing the backend `subscribe` function. No-op
/// until [AppConfig.pushSubscribeFunctionId] is configured.
Future<void> subscribePushTopics(Client client) async {
  if (AppConfig.pushSubscribeFunctionId.isEmpty) return;
  try {
    await Functions(client).createExecution(
      functionId: AppConfig.pushSubscribeFunctionId,
    );
  } catch (_) {
    // Subscription is best-effort; the user can still receive direct pushes.
  }
}
