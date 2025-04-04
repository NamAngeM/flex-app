// File generated for Firebase configuration based on google-services.json

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Configuration pour le Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC3FfKq9ohhVd4oy7TgxkhMoFCaHwhYMYw',
    appId: '1:631473048805:web:bff825bb8feafd1578180c', // Estimation basée sur l'ID Android
    messagingSenderId: '631473048805',
    projectId: 'flexbookrdv-2a945',
    authDomain: 'flexbookrdv-2a945.firebaseapp.com',
    storageBucket: 'flexbookrdv-2a945.firebasestorage.app',
  );

  // Configuration pour Android (extraite directement de google-services.json)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC3FfKq9ohhVd4oy7TgxkhMoFCaHwhYMYw',
    appId: '1:631473048805:android:bff825bb8feafd1578180c',
    messagingSenderId: '631473048805',
    projectId: 'flexbookrdv-2a945',
    storageBucket: 'flexbookrdv-2a945.firebasestorage.app',
  );

  // Configuration pour iOS (estimation basée sur les valeurs Android)
  // Remarque: Ces valeurs doivent être mises à jour si vous avez un fichier GoogleService-Info.plist
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC3FfKq9ohhVd4oy7TgxkhMoFCaHwhYMYw',
    appId: '1:631473048805:ios:bff825bb8feafd1578180c', // Estimation
    messagingSenderId: '631473048805',
    projectId: 'flexbookrdv-2a945',
    storageBucket: 'flexbookrdv-2a945.firebasestorage.app',
    iosClientId: '631473048805-igd6f9hivderv7mgafhrot5l0a5sipht.apps.googleusercontent.com',
    iosBundleId: 'com.example.flex_book_rdv',
  );

  // Configuration pour macOS (estimation basée sur les valeurs iOS)
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC3FfKq9ohhVd4oy7TgxkhMoFCaHwhYMYw',
    appId: '1:631473048805:ios:bff825bb8feafd1578180c', // Même que iOS
    messagingSenderId: '631473048805',
    projectId: 'flexbookrdv-2a945',
    storageBucket: 'flexbookrdv-2a945.firebasestorage.app',
    iosClientId: '631473048805-igd6f9hivderv7mgafhrot5l0a5sipht.apps.googleusercontent.com',
    iosBundleId: 'com.example.flex_book_rdv',
  );
}