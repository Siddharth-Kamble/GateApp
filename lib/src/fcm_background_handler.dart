import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase_options.dart';
import '../notification_service.dart';

/// ⚠️ MUST be a top-level function
/// ⚠️ MUST be annotated for background isolate
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  // ✅ Initialize Firebase safely
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }

  // 🔥 REQUIRED: initialize local notifications in background isolate
  await NotificationService().init();

  final data = message.data;

  // 🔔 Manually show notification (DATA-ONLY FCM)
  await NotificationService().showNotification(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: data['title'] ?? 'New Entry Approval',
    body: data['body'] ?? 'Approval required',
    payload: data,
  );
}
