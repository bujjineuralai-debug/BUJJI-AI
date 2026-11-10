import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration for the BUJJI AI Android application.
/// Values are taken from the Android app registered in Firebase project
/// bujji-ai-2e2af. Do not place service-account credentials in this file.
class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCIYT9YSWhNbEu-sok0Gw30V0s4aKFM5yQ',
    appId: '1:924828656704:android:4951d1764f058e794aaba5',
    messagingSenderId: '924828656704',
    projectId: 'bujji-ai-2e2af',
    storageBucket: 'bujji-ai-2e2af.firebasestorage.app',
  );
}
