import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase_options.dart';

/// Ye function TOP-LEVEL hona chahiye (class ke andar nahi)
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate me Firebase init
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      // agar koi aur error ho toh throw karo
      rethrow;
    } else {
      // ignore: avoid_print
      print('duplicate-app in background handler, ignoring.');
    }
  } catch (e) {
    // ignore: avoid_print
    print('Unknown error in background Firebase init: $e');
  }

  // Yaha tum apna background notification logic daal sakte ho
  // ignore: avoid_print
  print('📩 Background message: ${message.messageId}');
}
