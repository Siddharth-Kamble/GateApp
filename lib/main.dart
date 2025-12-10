import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

// UI
import 'package:flutter_application_1/src/ui/shared/role_selection.dart';

// FCM background handler (top-level function)
import 'src/fcm_background_handler.dart';

// Local notification service
import 'notification_service.dart';

// FlutterFire generated options
import 'firebase_options.dart';

// Auth provider
import 'src/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---------- 1) Firebase initialize (handle duplicate-app safely) ----------
  await _initFirebaseSafely();

  // ---------- 2) FCM background handler ----------
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e, s) {
    // ignore: avoid_print
    print('Error setting background FCM handler: $e');
    print(s);
  }

  // ---------- 3) Local notifications ----------
  try {
    await NotificationService().init();
  } catch (e, s) {
    // ignore: avoid_print
    print('NotificationService init failed: $e');
    print(s);
  }

  // ---------- 4) Run app ----------
  runApp(const MyGateApp());
}

Future<void> _initFirebaseSafely() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // ignore: avoid_print
    print('Firebase.initializeApp OK in main()');
  } on FirebaseException catch (e, s) {
    if (e.code == 'duplicate-app') {
      // Yaha aayega agar kisi plugin ne pehle hi init kar diya ho
      // ignore: avoid_print
      print(
        'Firebase default app already exists, ignoring duplicate-app in main().',
      );
    } else {
      // koi aur firebase error hua to usko dekh sakte ho
      // ignore: avoid_print
      print('FirebaseException during initializeApp: ${e.code} $e');
      print(s);
      rethrow;
    }
  } catch (e, s) {
    // ignore: avoid_print
    print('Unknown error during Firebase.initializeApp: $e');
    print(s);
  }
}

class MyGateApp extends StatelessWidget {
  const MyGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MyGate App',
        home: RoleSelectionPage(), // ← direct yahi open hoga
      ),
    );
  }
}
