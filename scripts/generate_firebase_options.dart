import 'dart:io';

void main() {
  final output = '''
// File generated from GitHub Secrets
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '${Platform.environment['FIREBASE_WEB_API_KEY'] ?? 'YOUR_WEB_API_KEY'}',
    appId: '${Platform.environment['FIREBASE_WEB_APP_ID'] ?? 'YOUR_WEB_APP_ID'}',
    messagingSenderId: '${Platform.environment['FIREBASE_MESSAGING_SENDER_ID'] ?? 'YOUR_MESSAGING_SENDER_ID'}',
    projectId: '${Platform.environment['FIREBASE_PROJECT_ID'] ?? 'YOUR_PROJECT_ID'}',
    authDomain: '${Platform.environment['FIREBASE_AUTH_DOMAIN'] ?? 'YOUR_PROJECT_ID.firebaseapp.com'}',
    storageBucket: '${Platform.environment['FIREBASE_STORAGE_BUCKET'] ?? 'YOUR_PROJECT_ID.firebasestorage.app'}',
    measurementId: '${Platform.environment['FIREBASE_MEASUREMENT_ID'] ?? 'YOUR_MEASUREMENT_ID'}',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '${Platform.environment['FIREBASE_ANDROID_API_KEY'] ?? 'YOUR_ANDROID_API_KEY'}',
    appId: '${Platform.environment['FIREBASE_ANDROID_APP_ID'] ?? 'YOUR_ANDROID_APP_ID'}',
    messagingSenderId: '${Platform.environment['FIREBASE_MESSAGING_SENDER_ID'] ?? 'YOUR_MESSAGING_SENDER_ID'}',
    projectId: '${Platform.environment['FIREBASE_PROJECT_ID'] ?? 'YOUR_PROJECT_ID'}',
    storageBucket: '${Platform.environment['FIREBASE_STORAGE_BUCKET'] ?? 'YOUR_PROJECT_ID.firebasestorage.app'}',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '${Platform.environment['FIREBASE_IOS_API_KEY'] ?? 'YOUR_IOS_API_KEY'}',
    appId: '${Platform.environment['FIREBASE_IOS_APP_ID'] ?? 'YOUR_IOS_APP_ID'}',
    messagingSenderId: '${Platform.environment['FIREBASE_MESSAGING_SENDER_ID'] ?? 'YOUR_MESSAGING_SENDER_ID'}',
    projectId: '${Platform.environment['FIREBASE_PROJECT_ID'] ?? 'YOUR_PROJECT_ID'}',
    storageBucket: '${Platform.environment['FIREBASE_STORAGE_BUCKET'] ?? 'YOUR_PROJECT_ID.firebasestorage.app'}',
    iosBundleId: 'com.coachclient.app',
  );
}
''';

  final file = File('lib/firebase_options.dart');
  file.writeAsStringSync(output);
  print('✅ Generated lib/firebase_options.dart from environment variables');
}






