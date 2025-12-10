import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class FCMService {
  // --- Save FCM token for the owner ---
  Future<void> saveOwnerFCMToken(String ownerId) async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users') // same collection where owners are saved
          .doc(ownerId)
          .update({'fcmToken': token});
      print('Owner FCM token saved: $token');
    }
  }

  // --- Send push notification to a specific FCM token ---
  Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      // Replace this with your actual Firebase Server Key
      const String serverKey = 'YOUR_FIREBASE_SERVER_KEY';

      final data = {
        "to": token,
        "notification": {"title": title, "body": body, "sound": "default"},
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "status": "done",
          "body": body,
          "title": title,
        },
      };

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode != 200) {
        throw Exception('FCM error: ${response.body}');
      } else {
        print('FCM sent successfully to $token');
      }
    } catch (e) {
      print('Error sending FCM: $e');
    }
  }
}
