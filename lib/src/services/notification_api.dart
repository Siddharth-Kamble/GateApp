import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationApi {
  static const String _baseUrl =
      "https://YOUR_RENDER_OR_FUNCTION_URL/sendNotification";

  static Future<void> notifyAllOwners({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": title,
          "body": body,
          "data": data ?? {},
        }),
      );
    } catch (e) {
      // Do not crash the app if notification fails
      print("Notification API error: $e");
    }
  }
}
