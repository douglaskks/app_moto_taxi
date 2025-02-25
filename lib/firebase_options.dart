// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        return windows;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCCoWdBAASY4bjkQFs6PXzmweqgm50Y2Vg',
    appId: '1:848362244720:web:e2588a1ae2cb0cae1d02b5',
    messagingSenderId: '848362244720',
    projectId: 'mototaxilajedo',
    authDomain: 'mototaxilajedo.firebaseapp.com',
    storageBucket: 'mototaxilajedo.firebasestorage.app',
    measurementId: 'G-WQ3P0LM066',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAAJgAP1unJGwETi-je8c1zbuTcVrX0Fz4',
    appId: '1:848362244720:android:6db37d3566cf02221d02b5',
    messagingSenderId: '848362244720',
    projectId: 'mototaxilajedo',
    storageBucket: 'mototaxilajedo.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBk7z7f0aD4M1fapmuE4kAlGxXJIBNZenc',
    appId: '1:848362244720:ios:05ba986a58f9cafe1d02b5',
    messagingSenderId: '848362244720',
    projectId: 'mototaxilajedo',
    storageBucket: 'mototaxilajedo.firebasestorage.app',
    iosBundleId: 'com.example.appMotoTaxe',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBk7z7f0aD4M1fapmuE4kAlGxXJIBNZenc',
    appId: '1:848362244720:ios:05ba986a58f9cafe1d02b5',
    messagingSenderId: '848362244720',
    projectId: 'mototaxilajedo',
    storageBucket: 'mototaxilajedo.firebasestorage.app',
    iosBundleId: 'com.example.appMotoTaxe',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCCoWdBAASY4bjkQFs6PXzmweqgm50Y2Vg',
    appId: '1:848362244720:web:303c6366d1aaa1ac1d02b5',
    messagingSenderId: '848362244720',
    projectId: 'mototaxilajedo',
    authDomain: 'mototaxilajedo.firebaseapp.com',
    storageBucket: 'mototaxilajedo.firebasestorage.app',
    measurementId: 'G-FBLLB13Y94',
  );
}
