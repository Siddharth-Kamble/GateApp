// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:convert';
// import 'dart:io' show HttpHeaders, File;

// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/src/services/cloudinary_service.dart' show CloudinaryService;
// import 'package:flutter_image_compress/flutter_image_compress.dart' show CompressFormat, FlutterImageCompress;
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
// import 'package:cloud_firestore/cloud_firestore.dart';

// import 'package:http/http.dart' as http;

// class RegisterVisit extends StatefulWidget {
//   final String guardUid;
//   final String guardName;

//   const RegisterVisit({
//     super.key,
//     required this.guardUid,
//     required this.guardName,
//   });

//   @override
//   State<RegisterVisit> createState() => _RegisterVisitState();
// }

// class _RegisterVisitState extends State<RegisterVisit> {
//   final _formKey = GlobalKey<FormState>();
//   final ImagePicker _picker = ImagePicker();

//   File? photo;

//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _mobileController = TextEditingController();
//   final TextEditingController _reasonController = TextEditingController();

//   bool _isSubmitting = false;

//   static const String _backendUrl =
//       'https://fcm-server-s0z6.onrender.com/notify-owner';
//   static const String _companyOwnerId = 'iDyPReum390W77oiFJhp';

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _mobileController.dispose();
//     _reasonController.dispose();
//     super.dispose();
//   }

//   // ---------------- IMAGE PICK ----------------
//   Future<void> pickImage() async {
//     // Show dialog for selecting either Camera or Gallery
//     final pickedSource = await showDialog<ImageSource>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Select Image Source'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context, ImageSource.camera);
//             },
//             child: Text('Camera'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context, ImageSource.gallery);
//             },
//             child: Text('Gallery'),
//           ),
//         ],
//       ),
//     );

//     // If user cancels, exit
//     if (pickedSource == null) return;

//     // Pick image from the selected source
//     final XFile? img = await _picker.pickImage(source: pickedSource);
//     if (img == null) return;

//     final File original = File(img.path);
//     final File? compressed = await _compressImage(original);

//     if (compressed != null) {
//       setState(() => photo = compressed);
//     }
//   }

//  //---------------- IMAGE COMPRESSION ----------------
//  Future<File?> _compressImage(File file) async {
//   try {
//     final dir = await getTemporaryDirectory();
//     final targetPath = path.join(
//       dir.path,
//       '${DateTime.now().millisecondsSinceEpoch}.jpg',
//     );

//     final Uint8List? bytes =
//         await FlutterImageCompress.compressWithFile(
//       file.path,
//       minWidth: 1080,
//       minHeight: 1080,
//       quality: 75,
//       keepExif: true,
//       format: CompressFormat.jpeg,
//     );

//     if (bytes == null) return null;

//     final compressedFile = File(targetPath);
//     await compressedFile.writeAsBytes(bytes, flush: true);

//     return compressedFile;
//   } catch (e, stackTrace) {
//     debugPrint('Image compression failed: $e');
//     debugPrintStack(stackTrace: stackTrace);
//     return null;
//   }
// }


//   // ---------------- IMAGE UPLOAD ----------------

//   // ---------------- NOTIFY OWNER ----------------
//   Future<void> _notifyOwner(String passId) async {
//     await http.post(
//       Uri.parse(_backendUrl),
//       headers: {HttpHeaders.contentTypeHeader: "application/json"},
//       body: jsonEncode({
//         "ownerId": _companyOwnerId,
//         "passId": passId,
//         "type": "visitor",
//       }),
//     );
//   }

//   // ---------------- SUBMIT ----------------
//   Future<void> submit() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isSubmitting = true);

//     try {
//       // 1️⃣ Upload image to Cloudinary (ONLY ADDITION)
//       String? imageUrl;
//       if (photo != null) {
//         imageUrl = await CloudinaryService.uploadImage(photo!);
//       }

//       // 2️⃣ Save visitor data to Firestore
//       final docRef =
//           await FirebaseFirestore.instance.collection("passes").add({
//         "type": "visitor",
//         "name": _nameController.text.trim(), // ✅ IMPORTANT
//         "mobile": _mobileController.text.trim(),
//         "reason": _reasonController.text.trim(), // ✅ IMPORTANT
//         "createdAt": FieldValue.serverTimestamp(),
//         "status": "pending",
//         "isEntered": false,
//         "imageUrl": imageUrl, // ✅ Cloudinary URL
//         "addedBy": widget.guardUid,
//         "guardName": widget.guardName,
//       });

//       // 3️⃣ Notify owner (UNCHANGED)
//       await _notifyOwner(docRef.id);

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Visitor registered successfully"),
//           backgroundColor: Colors.green,
//         ),
//       );
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e")),
//       );
//     } finally {
//       if (mounted) setState(() => _isSubmitting = false);
//     }
//   }

//   // ---------------- INPUT FIELD ----------------
//   Widget _input({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     int maxLines = 1,
//     TextInputType keyboard = TextInputType.text,
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: keyboard,
//       maxLines: maxLines,
//       validator: (v) => v == null || v.isEmpty ? "$label required" : null,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         filled: true,
//         fillColor: Colors.white,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//         ),
//       ),
//     );
//   }

//   // ---------------- IMAGE PICKER UI ----------------
//   Widget _imagePicker() {
//     return GestureDetector(
//       onTap: pickImage,
//       child: CircleAvatar(
//         radius: 60,
//         backgroundColor: Colors.blue.shade100,
//         backgroundImage: photo != null ? FileImage(photo!) : null,
//         child: photo == null
//             ? const Icon(Icons.camera_alt, size: 40, color: Colors.blue)
//             : null,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F6FB),
//       appBar: AppBar(
//         title: const Text(
//           "Register Visitor",
//           style: TextStyle(fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.green.shade700,
//         foregroundColor: Colors.white,
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               _imagePicker(),
//               const SizedBox(height: 24),
//               _input(
//                 controller: _nameController,
//                 label: "Visitor Name",
//                 icon: Icons.person,
//               ),
//               const SizedBox(height: 16),
//               _input(
//                 controller: _mobileController,
//                 label: "Mobile Number",
//                 icon: Icons.phone,
//                 keyboard: TextInputType.phone,
//               ),
//               const SizedBox(height: 16),
//               _input(
//                 controller: _reasonController,
//                 label: "Purpose of Visit",
//                 icon: Icons.info_outline,
//                 maxLines: 3,
//               ),
//               const SizedBox(height: 30),
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: _isSubmitting ? null : submit,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green.shade700,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                   child: _isSubmitting
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           "Register Visitor",
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io' show HttpHeaders, File;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/services/cloudinary_service.dart' show CloudinaryService;
import 'package:flutter_image_compress/flutter_image_compress.dart' show CompressFormat, FlutterImageCompress;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:http/http.dart' as http;

class RegisterVisit extends StatefulWidget {
  final String guardUid;
  final String guardName;

  const RegisterVisit({
    super.key,
    required this.guardUid,
    required this.guardName,
  });

  @override
  State<RegisterVisit> createState() => _RegisterVisitState();
}

class _RegisterVisitState extends State<RegisterVisit> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  File? photo;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  bool _isSubmitting = false;

  static const String _backendUrl =
      'https://fcm-server-s0z6.onrender.com/notify-owner';
  static const String _companyOwnerId = 'iDyPReum390W77oiFJhp';

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // ---------------- IMAGE PICK ----------------
 Future<void> pickImage() async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Select Image Source'),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await Future.delayed(const Duration(milliseconds: 300));
            if (!mounted) return;
            _pickFromSource(ImageSource.camera);
          },
          child: const Text('Camera'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await Future.delayed(const Duration(milliseconds: 300));
            if (!mounted) return;
            _pickFromSource(ImageSource.gallery);
          },
          child: const Text('Gallery'),
        ),
      ],
    ),
  );
}




Future<void> _pickFromSource(ImageSource source) async {
  final XFile? img = await _picker.pickImage(source: source);
  if (img == null) return;

  final File original = File(img.path);
  final File? compressed = await _compressImage(original);

  if (compressed != null && mounted) {
    setState(() => photo = compressed);
  }
}
 //---------------- IMAGE COMPRESSION ----------------
Future<File?> _compressImage(File file) async {
  try {
    final dir = await getTemporaryDirectory();
    int quality = 70;
    int minWidth = 800;

    Uint8List? compressedBytes;

    do {
      compressedBytes = await FlutterImageCompress.compressWithFile(
        file.path,
        minWidth: minWidth,
        minHeight: minWidth,
        quality: quality,
        keepExif: false,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null) return null;

      final sizeInKB = compressedBytes.lengthInBytes / 1024;

      debugPrint(
        "Compression -> Quality: $quality | Width: $minWidth | Size: ${sizeInKB.toStringAsFixed(2)} KB",
      );

      quality -= 10;
      minWidth -= 100;

      if (quality <= 20) break;
    } while (compressedBytes.lengthInBytes > 100 * 1024);

    final targetPath = path.join(
      dir.path,
      "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg",
    );

    final compressedFile = File(targetPath);
    await compressedFile.writeAsBytes(compressedBytes, flush: true);

    return compressedFile;
  } catch (e, stackTrace) {
    debugPrint("Image compression failed: $e");
    debugPrintStack(stackTrace: stackTrace);
    return null;
  }
}



  // ---------------- IMAGE UPLOAD ----------------

  // ---------------- NOTIFY OWNER ----------------
  Future<void> _notifyOwner(String passId) async {
    await http.post(
      Uri.parse(_backendUrl),
      headers: {HttpHeaders.contentTypeHeader: "application/json"},
      body: jsonEncode({
        "ownerId": _companyOwnerId,
        "passId": passId,
        "type": "visitor",
      }),
    );
  }

  // ---------------- SUBMIT ----------------
  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // 1️⃣ Upload image to Cloudinary (ONLY ADDITION)
      String? imageUrl;
      if (photo != null) {
        imageUrl = await CloudinaryService.uploadImage(photo!);
      }

      // 2️⃣ Save visitor data to Firestore
      final docRef =
          await FirebaseFirestore.instance.collection("passes").add({
        "type": "visitor",
        "name": _nameController.text.trim(), // ✅ IMPORTANT
        "mobile": _mobileController.text.trim(),
        "reason": _reasonController.text.trim(), // ✅ IMPORTANT
        "createdAt": FieldValue.serverTimestamp(),
        "status": "pending",
        "isEntered": false,
        "imageUrl": imageUrl, // ✅ Cloudinary URL
        "addedBy": widget.guardUid,
        "guardName": widget.guardName,
      });

      // 3️⃣ Notify owner (UNCHANGED)
      await _notifyOwner(docRef.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Visitor registered successfully"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ---------------- INPUT FIELD ----------------
  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: (v) => v == null || v.isEmpty ? "$label required" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ---------------- IMAGE PICKER UI ----------------
  Widget _imagePicker() {
    return GestureDetector(
      onTap: pickImage,
      child: CircleAvatar(
        radius: 60,
        backgroundColor: Colors.blue.shade100,
        backgroundImage: photo != null ? FileImage(photo!) : null,
        child: photo == null
            ? const Icon(Icons.camera_alt, size: 40, color: Colors.blue)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text(
          "Register Visitor",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _imagePicker(),
              const SizedBox(height: 24),
              _input(
                controller: _nameController,
                label: "Visitor Name",
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _input(
                controller: _mobileController,
                label: "Mobile Number",
                icon: Icons.phone,
                keyboard: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _input(
                controller: _reasonController,
                label: "Purpose of Visit",
                icon: Icons.info_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Register Visitor",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
