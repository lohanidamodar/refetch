/// Static configuration for the Refetch app.
///
/// The app talks to two backends:
///  * Appwrite (auth only) via the Dart SDK.
///  * The existing refetch.io REST API for reads and mutations.
class AppConfig {
  AppConfig._();

  /// Appwrite Cloud endpoint hosting the refetch project.
  static const String appwriteEndpoint = 'https://fra.cloud.appwrite.io/v1';

  /// Refetch Appwrite project id.
  static const String appwriteProjectId = '63ef1792594ff4f50de2';

  /// Base URL of the refetch.io Next.js API.
  static const String apiBaseUrl = 'https://refetch.io';

  /// Page size used for feed pagination.
  static const int feedPageSize = 25;

  /// Brand colour (refetch purple).
  static const int brandColor = 0xFF7C3AED;

  /// Appwrite Function id for the push topic-subscribe function. Left empty
  /// until the backend functions are deployed; while empty, the app skips the
  /// best-effort topic subscription. See docs/push-notifications-setup.md.
  static const String pushSubscribeFunctionId = '';

  /// Appwrite Messaging provider ids. Android registers its FCM token against
  /// the FCM provider; iOS registers its APNS token against the APNS provider —
  /// each provider delivers directly to its platform (no FCM→APNS relay). Left
  /// empty until the providers are created in the Appwrite console; when empty,
  /// Appwrite picks a matching provider by the target's platform automatically.
  static const String fcmProviderId = '6a1bb5a3001dc2d85de3';
  static const String apnsProviderId = '';

  /// Android notification channel used for foreground display.
  static const String androidNotificationChannelId = 'refetch_default';
  static const String androidNotificationChannelName = 'Refetch';
}
