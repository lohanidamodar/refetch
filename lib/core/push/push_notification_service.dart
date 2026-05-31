import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:push/push.dart';

import '../config/app_config.dart';
import 'push_registrar.dart';
import 'topic_subscriptions.dart';

/// Top-level background-message handler. The OS displays notification-type
/// messages automatically; taps are delivered to [Push.addOnNotificationTap].
@pragma('vm:entry-point')
Future<void> onBackgroundPushMessage(RemoteMessage message) async {
  // No work needed in the background isolate.
}

/// Bridges device push notifications into the app using the `push` plugin,
/// which talks to FCM on Android and **APNS directly on iOS (no Firebase)**.
///
/// The device token is registered against the matching Appwrite Messaging
/// provider — the FCM token → FCM provider on Android, the APNS token → APNS
/// provider on iOS. All plugin access is guarded so the app runs normally on
/// platforms where push is unavailable (desktop) or unconfigured.
class PushNotificationService {
  PushNotificationService(
    this._registrar,
    this._topics, {
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _local = localNotifications ?? FlutterLocalNotificationsPlugin();

  final PushRegistrar _registrar;
  final TopicSubscriptions _topics;
  final FlutterLocalNotificationsPlugin _local;

  bool _available = false;
  bool _initialized = false;
  bool _signedIn = false;
  bool _registering = false;
  void Function(String postId)? _onOpenThread;
  final List<VoidCallback> _unsubscribes = [];

  /// True once the push plugin set up successfully on this platform.
  bool get isAvailable => _available;

  /// Wires notification channels and message listeners. [onOpenThread] is
  /// called with a post id when the user taps a notification.
  Future<void> initialize({
    required void Function(String postId) onOpenThread,
  }) async {
    if (_initialized) return;
    _initialized = true;
    _onOpenThread = onOpenThread;

    try {
      await _setUpLocalNotifications();

      _unsubscribes.add(Push.instance.addOnMessage(_showForeground));
      _unsubscribes.add(Push.instance.addOnBackgroundMessage(onBackgroundPushMessage));
      _unsubscribes.add(Push.instance.addOnNotificationTap(_handleTapData));
      _unsubscribes.add(
        Push.instance.addOnNewToken((token) {
          if (_signedIn) _registrar.register(token, providerId: _providerId());
        }),
      );

      // App launched from terminated state by tapping a notification.
      final launchData =
          await Push.instance.notificationTapWhichLaunchedAppFromTerminated;
      if (launchData != null) _handleTapData(launchData);

      _available = true;
    } catch (error) {
      debugPrint('Push unavailable on this platform: $error');
      return;
    }

    // Handles the case where the user was already signed in before init.
    await _registerIfPossible();
  }

  /// Requests OS notification permission via permission_handler. Returns true
  /// if granted (or provisionally granted on iOS).
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted || status.isProvisional || status.isLimited;
    } catch (_) {
      return false;
    }
  }

  /// Called when the user signs in. Registers the device token if push is
  /// available now, otherwise defers until [initialize] completes.
  Future<void> onSignedIn() async {
    _signedIn = true;
    await _registerIfPossible();
  }

  /// Called on sign-out: removes the Appwrite push target.
  Future<void> onSignedOut() async {
    _signedIn = false;
    _registering = false;
    await _registrar.unregister();
  }

  /// Registers the current device token against the matching Appwrite provider.
  /// Idempotent and safe to call from both [onSignedIn] and [initialize].
  Future<void> _registerIfPossible() async {
    if (!_available || !_signedIn || _registering) return;
    _registering = true;

    await requestPermission();
    try {
      final token = await Push.instance.token;
      // On iOS the APNS token may not be ready yet; addOnNewToken will register
      // it once available.
      if (token != null) {
        final targetId = await _registrar.register(
          token,
          providerId: _providerId(),
        );
        if (targetId != null) await _topics.syncOnRegister(targetId);
      }
    } catch (error) {
      debugPrint('Could not register push token: $error');
    }
  }

  /// FCM provider on Android, APNS provider on iOS.
  String _providerId() {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? AppConfig.apnsProviderId
        : AppConfig.fcmProviderId;
  }

  Future<void> _setUpLocalNotifications() async {
    const androidChannel = AndroidNotificationChannel(
      AppConfig.androidNotificationChannelId,
      AppConfig.androidNotificationChannelName,
      importance: Importance.high,
    );

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _openFromPayload(payload);
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConfig.androidNotificationChannelId,
          AppConfig.androidNotificationChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(_stringKeyed(message.data)),
    );
  }

  void _handleTapData(Map<String?, Object?> data) {
    final postId = data['postId'];
    if (postId is String && postId.isNotEmpty) {
      _onOpenThread?.call(postId);
    }
  }

  void _openFromPayload(String payload) {
    try {
      final data = jsonDecode(payload);
      final postId = data is Map ? data['postId'] : null;
      if (postId is String && postId.isNotEmpty) {
        _onOpenThread?.call(postId);
      }
    } catch (_) {
      // Malformed payload — ignore.
    }
  }

  Map<String, Object?> _stringKeyed(Map<String?, Object?>? data) {
    if (data == null) return const {};
    return {
      for (final entry in data.entries)
        if (entry.key != null) entry.key!: entry.value,
    };
  }

  void dispose() {
    for (final unsubscribe in _unsubscribes) {
      unsubscribe();
    }
    _unsubscribes.clear();
  }
}
