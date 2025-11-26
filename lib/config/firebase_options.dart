// GENERATED CODE - DO NOT MODIFY BY HAND
//
// Replace the placeholder values below with your Firebase project's
// configuration, or run `flutterfire configure` to generate this file.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (Platform.isAndroid) return android;
    if (Platform.isIOS) return ios;
    if (Platform.isMacOS) return macos;
    if (Platform.isWindows) return windows;
    if (Platform.isLinux) return linux;
    throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
  }

  // Web
  static const FirebaseOptions web = FirebaseOptions(
    // For Firebase JS SDK v7.20.0 and later, measurementId is optional

  apiKey: "AIzaSyDTSMiQCLmiqwsFPSjFAE4dPOB0jrqcJYo",
  authDomain: "vmsweb-ba516.firebaseapp.com",
  projectId: "vmsweb-ba516",
  // Use Firebase Storage bucket hostname (default: <project>.appspot.com)
  storageBucket: "vmsweb-ba516.appspot.com",
  messagingSenderId: "812984256624",
  appId: "1:812984256624:web:434bf28b6aeeb55ddd0cb5",
  measurementId: "G-93EGNPW0X6"

  );

  // Android
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyAMGZONYqaRKPxpzBqctlaDUTa-5bGM7I0',
  appId: '1:812984256624:android:e03e5e035042694cdd0cb5',
  messagingSenderId: '812984256624',
  projectId: 'vmsweb-ba516',
  storageBucket: 'vmsweb-ba516.appspot.com',
);


  // iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'YOUR_IOS_BUNDLE_ID',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'YOUR_MACOS_BUNDLE_ID',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_WINDOWS_API_KEY',
    appId: 'YOUR_WINDOWS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'YOUR_LINUX_API_KEY',
    appId: 'YOUR_LINUX_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT.appspot.com',
  );
}
