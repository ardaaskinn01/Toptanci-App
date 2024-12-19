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
    apiKey: 'AIzaSyDEZGFZo_fwNbAC7xC0glFbL1pRsvMK3J8',
    appId: '1:478350038053:web:76eb6e924df3d821325bcc',
    messagingSenderId: '478350038053',
    projectId: 'toptanci-e9168',
    authDomain: 'toptanci-e9168.firebaseapp.com',
    storageBucket: 'toptanci-e9168.firebasestorage.app',
    measurementId: 'G-1FP8ZPBFGV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCbgwErThl9Iz2NYPfs6BFC4iP2pUwZUbg',
    appId: '1:478350038053:android:22e44f83d62eed1d325bcc',
    messagingSenderId: '478350038053',
    projectId: 'toptanci-e9168',
    storageBucket: 'toptanci-e9168.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyACEzjfS14Ae-Z6MI_VM2aFy17wIGTT7Cs',
    appId: '1:478350038053:ios:e9f525551e51e6c9325bcc',
    messagingSenderId: '478350038053',
    projectId: 'toptanci-e9168',
    storageBucket: 'toptanci-e9168.firebasestorage.app',
    iosBundleId: 'com.example.toptanci',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyACEzjfS14Ae-Z6MI_VM2aFy17wIGTT7Cs',
    appId: '1:478350038053:ios:e9f525551e51e6c9325bcc',
    messagingSenderId: '478350038053',
    projectId: 'toptanci-e9168',
    storageBucket: 'toptanci-e9168.firebasestorage.app',
    iosBundleId: 'com.example.toptanci',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDEZGFZo_fwNbAC7xC0glFbL1pRsvMK3J8',
    appId: '1:478350038053:web:62ccb1bc7a46736b325bcc',
    messagingSenderId: '478350038053',
    projectId: 'toptanci-e9168',
    authDomain: 'toptanci-e9168.firebaseapp.com',
    storageBucket: 'toptanci-e9168.firebasestorage.app',
    measurementId: 'G-2T41BSD2ZK',
  );
}