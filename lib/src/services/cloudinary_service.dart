// import 'dart:io';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class CloudinaryService {
//   static const String cloudName = "dl4gyyily";
//   static const String uploadPreset = "gate_upload"; // 👈 HERE

//   static Future<String?> uploadImage(File imageFile) async {
//     final uri = Uri.parse(
//       "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
//     );

//     final request = http.MultipartRequest("POST", uri)
//       ..fields['upload_preset'] = uploadPreset // 👈 USED HERE
//       ..files.add(
//         await http.MultipartFile.fromPath(
//           'file',
//           imageFile.path,
//         ),
//       );

//     final response = await request.send();
//     final resBody = await response.stream.bytesToString();

//     if (response.statusCode == 200) {
//       final json = jsonDecode(resBody);
//       return json['secure_url']; // 👈 IMAGE URL
//     } else {
//       print("Cloudinary upload failed: $resBody");
//       return null;
//     }
//   }
// }
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data'; // ✅ ADD
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = "dl4gyyily";
  static const String uploadPreset = "gate_upload";

  // 🔹 EXISTING METHOD (UNCHANGED)
  static Future<String?> uploadImage(File imageFile) async {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(resBody);
      return json['secure_url'];
    } else {
      print("Cloudinary upload failed: $resBody");
      return null;
    }
  }

  // 🔹 NEW METHOD (WEB SUPPORT ONLY)
  static Future<String?> uploadImageBytes(Uint8List bytes) async {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: 'vehicle_image.jpg',
        ),
      );

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(resBody);
      return json['secure_url'];
    } else {
      print("Cloudinary upload failed: $resBody");
      return null;
    }
  }
}
