import 'package:appwrite/appwrite.dart';

import 'api_exception.dart';

/// Extracts a human-readable message from any error raised by the app's two
/// backends:
///  * [ApiException] — from the refetch.io REST client.
///  * [AppwriteException] — from the Appwrite SDK (auth, push targets).
///
/// Falls back to [fallback] only when no useful message is available, so the
/// user sees the real reason (e.g. "Invalid credentials") instead of a generic
/// failure string.
String messageForError(
  Object? error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is ApiException) {
    return error.message.trim().isNotEmpty ? error.message : fallback;
  }
  if (error is AppwriteException) {
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) return message;
  }
  return fallback;
}
