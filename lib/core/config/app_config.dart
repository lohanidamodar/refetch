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
}
