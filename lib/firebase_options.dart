import "package:firebase_core/firebase_core.dart" show FirebaseOptions;
import "package:flutter/foundation.dart"
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          "DefaultFirebaseOptions are not configured for this platform.",
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyAQXB2fBv7pVv0pepoC0AyA17xcTSztWh0",
    appId: "1:172889864684:web:f2fd17e4475db5b989a8c9",
    messagingSenderId: "172889864684",
    projectId: "novariseapp",
    authDomain: "novariseapp.firebaseapp.com",
    storageBucket: "novariseapp.firebasestorage.app",
    measurementId: "G-070NFT2XZ2",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyCfgJ6lMceYwWlZsKEWfGakslqXOMrcqiM",
    appId: "1:172889864684:android:920e76bf75a0ca4289a8c9",
    messagingSenderId: "172889864684",
    projectId: "novariseapp",
    storageBucket: "novariseapp.firebasestorage.app",
  );
}
