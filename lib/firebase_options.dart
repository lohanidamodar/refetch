// PLACEHOLDER Firebase configuration.
//
// These are NOT real credentials — they let the project compile and run with
// push notifications safely disabled at runtime (token fetch fails and is
// caught). Replace this whole file by running:
//
//     flutterfire configure --project=<your-firebase-project>
//
// See docs/push-notifications-setup.md for the full checklist.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the current platform.
///
/// Returns placeholder options for mobile platforms and throws on platforms
/// where push is not configured (desktop), which callers guard against.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web push is not configured. Run flutterfire configure to enable it.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return _ios;
      default:
        throw UnsupportedError(
          'Push notifications are not configured for $defaultTargetPlatform.',
        );
    }
  }

  // Placeholder values. Format is plausible so Firebase.initializeApp accepts
  // them; they will not authenticate against any real Firebase project.
  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'AIzaSyPLACEHOLDER-replace-with-flutterfire-configure',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'refetch-placeholder',
    storageBucket: 'refetch-placeholder.appspot.com',
  );

  static const FirebaseOptions _ios = FirebaseOptions(
    apiKey: 'AIzaSyPLACEHOLDER-replace-with-flutterfire-configure',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'refetch-placeholder',
    storageBucket: 'refetch-placeholder.appspot.com',
    iosBundleId: 'io.appwrite.refetch',
  );
}
