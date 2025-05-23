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
    apiKey: 'AIzaSyDV_lisG0ICJTEx7OwERKjl8n6yhw8wB1I',
    appId: '1:742668763285:web:a562663a6a9ee2bbc69b9c',
    messagingSenderId: '742668763285',
    projectId: 'fitness-af7f2',
    authDomain: 'fitness-af7f2.firebaseapp.com',
    storageBucket: 'fitness-af7f2.appspot.com',
    measurementId: 'G-W6V0XWQQ04',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAngvW55DFs8OH5WImHHEBGbV385dgKfAY',
    appId: '1:742668763285:android:aa5403045dc5f9f6c69b9c',
    messagingSenderId: '742668763285',
    projectId: 'fitness-af7f2',
    storageBucket: 'fitness-af7f2.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBxqQSCmZFxS8J4F-_zlrhpn8to5QqiYTk',
    appId: '1:742668763285:ios:b4824477ac3088e4c69b9c',
    messagingSenderId: '742668763285',
    projectId: 'fitness-af7f2',
    storageBucket: 'fitness-af7f2.appspot.com',
    iosBundleId: 'com.example.fitness',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBxqQSCmZFxS8J4F-_zlrhpn8to5QqiYTk',
    appId: '1:742668763285:ios:b4824477ac3088e4c69b9c',
    messagingSenderId: '742668763285',
    projectId: 'fitness-af7f2',
    storageBucket: 'fitness-af7f2.appspot.com',
    iosBundleId: 'com.example.fitness',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDV_lisG0ICJTEx7OwERKjl8n6yhw8wB1I',
    appId: '1:742668763285:web:17ea9ba888787223c69b9c',
    messagingSenderId: '742668763285',
    projectId: 'fitness-af7f2',
    authDomain: 'fitness-af7f2.firebaseapp.com',
    storageBucket: 'fitness-af7f2.appspot.com',
    measurementId: 'G-RSX0P1Q6YM',
  );
}
