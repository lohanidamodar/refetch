import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../config/app_config.dart';
import 'push_registrar.dart';

/// Top-level background handler. Must be a top-level / static function annotated
/// with `@pragma('vm:entry-point')`. The OS displays notification-type messages
/// automatically; we don't need to do work here, but the handler must exist.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: data is delivered to onMessageOpenedApp / getInitialMessage on tap.
}

/// Initializes Firebase + local notifications and bridges incoming messages to
/// the app. All Firebase access is guarded so the app runs normally with the
/// placeholder `firebase_options.dart` (push is simply disabled).
class PushNotificationService {
  PushNotificationService(
    this._registrar, {
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _local = localNotifications ?? FlutterLocalNotificationsPlugin();

  final PushRegistrar _registrar;
  final FlutterLocalNotificationsPlugin _local;

  bool _available = false;
  bool _initialized = false;
  bool _signedIn = false;
  bool _registering = false;
  bool _tokenListenerAdded = false;
  void Function(String postId)? _onOpenThread;

  final List<StreamSubscription<dynamic>> _subs = [];

  /// True once Firebase initialized successfully (real config present).
  bool get isAvailable => _available;

  /// Sets up Firebase, notification channels, and message listeners.
  /// [onOpenThread] is called with a post id when the user taps a notification.
  Future<void> initialize({
    required void Function(String postId) onOpenThread,
  }) async {
    if (_initialized) return;
    _initialized = true;
    _onOpenThread = onOpenThread;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _available = true;
    } catch (error) {
      debugPrint('Push disabled (Firebase not configured): $error');
      return;
    }

    await _setUpLocalNotifications();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _subs.add(FirebaseMessaging.onMessage.listen(_showForeground));
    _subs.add(
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedFromMessage),
    );

    // App launched from terminated state by tapping a notification.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleOpenedFromMessage(initial);

    // If the user was already signed in before push finished initializing,
    // register their token now (handles the auth-resolves-before-init race).
    await _registerIfPossible();
  }

  /// Requests OS notification permission. Returns true if granted.
  Future<bool> requestPermission() async {
    if (!_available) return false;
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Called when the user signs in. Registers the device token if push is
  /// available now, otherwise defers until [initialize] completes.
  Future<void> onSignedIn() async {
    _signedIn = true;
    await _registerIfPossible();
  }

  /// Registers the platform-appropriate device token against the matching
  /// Appwrite provider — the FCM token → FCM provider on Android, the APNS
  /// token → APNS provider on iOS (each delivers directly to its platform).
  ///
  /// Idempotent: safe to call from both [onSignedIn] and [initialize]; the
  /// refresh listener is attached at most once.
  Future<void> _registerIfPossible() async {
    if (!_available || !_signedIn || _registering) return;
    _registering = true;

    await requestPermission();
    try {
      final token = await _deviceToken();
      if (token != null) {
        await _registrar.register(token, providerId: _providerId());
      }
    } catch (error) {
      debugPrint('Could not fetch push token: $error');
    }

    // Only the FCM token refreshes; the APNS token is stable per install.
    if (defaultTargetPlatform == TargetPlatform.android && !_tokenListenerAdded) {
      _tokenListenerAdded = true;
      _subs.add(
        FirebaseMessaging.instance.onTokenRefresh.listen((token) {
          if (_signedIn) {
            _registrar.register(token, providerId: _providerId());
          }
        }),
      );
    }
  }

  /// FCM registration token on Android, APNS device token on iOS.
  Future<String?> _deviceToken() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return FirebaseMessaging.instance.getAPNSToken();
    }
    return FirebaseMessaging.instance.getToken();
  }

  String _providerId() {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? AppConfig.apnsProviderId
        : AppConfig.fcmProviderId;
  }

  /// Called on sign-out: removes the Appwrite push target.
  Future<void> onSignedOut() async {
    _signedIn = false;
    _registering = false;
    await _registrar.unregister();
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
      payload: jsonEncode(message.data),
    );
  }

  void _handleOpenedFromMessage(RemoteMessage message) {
    final postId = message.data['postId'];
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

  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }
}
