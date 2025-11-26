import 'dart:async';
import 'package:vms/screens/home_screen.dart';
import 'package:vms/screens/auth/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'config/app_config.dart';
import 'config/firebase_options.dart';

Future<void> main() async {
  // Show Flutter errors on-screen and forward to the console/zone.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // Display a visible error UI so blank screens show the error message.
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('A runtime error occurred:', style: TextStyle(fontSize: 18, color: Colors.red)),
                const SizedBox(height: 8),
                Text(details.exceptionAsString(), style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                Text(details.stack.toString(), style: const TextStyle(fontSize: 12))
              ],
            ),
          ),
        ),
      ),
    );
  };

  // Catch errors from Flutter framework and Dart zones to log and display them.
  FlutterError.onError = (FlutterErrorDetails details) {
    // Print to console as well
    FlutterError.dumpErrorToConsole(details);
  };
  await runZonedGuarded(() async {
    // Ensure the Flutter bindings are initialized in the same zone
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppConfig.firebaseAvailable = true;
    } catch (e, s) {
      // If Firebase fails to initialize, log it and continue launching the app
      // in a degraded/offline mode so you can connect Firebase later.
      AppConfig.firebaseAvailable = false;
      print('Firebase.initializeApp() failed: $e');
      print(s);
    }

    runApp(const MyApp());
  }, (error, stack) {
    // Log uncaught async errors
    print('Uncaught async error: $error');
    print(stack);
  });
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Email And Password Login',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      debugShowCheckedModeBanner: false,
      home: Builder(builder: (context) {
        // If Firebase isn't available (e.g. web config missing), let the app
        // continue in degraded mode so you can connect Firebase later.
        if (!AppConfig.firebaseAvailable || Firebase.apps.isEmpty) {
          // Show the login screen but the app will be in a degraded mode; many
          // features that rely on Firebase will be disabled until you connect.
          return const LoginScreen();
        }

        final user = FirebaseAuth.instance.currentUser;
        return (user != null) ? const HomeScreen() : const LoginScreen();
      }),
    );
  }
}
