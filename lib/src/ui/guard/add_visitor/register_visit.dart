// register_visit.dart
import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class RegisterVisit extends StatefulWidget {
  final String guardUid;

  const RegisterVisit({
    super.key,
    required this.guardUid,
  }); // removed ownerFcmToken

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

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.camera);
    if (img != null) {
      File? compressed = await _compressImage(File(img.path));
      if (compressed != null) {
        setState(() => photo = compressed);
      }
    }
  }

  Future<File?> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(
      dir.path,
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    Uint8List? result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 50,
    );

    if (result == null) return null;

    int currentQuality = 50;
    while ((result?.length ?? 0) > 100 * 1024 && currentQuality > 10) {
      currentQuality -= 10;
      result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: currentQuality,
      );
      if (result == null) return null;
    }

    final compressedFile = File(targetPath);
    await compressedFile.writeAsBytes(result!.toList());
    return compressedFile;
  }

  Future<String?> _uploadImage(String docId) async {
    if (photo == null) return null;

    try {
      final ref = firebase_storage.FirebaseStorage.instance.ref().child(
        "visitor_photos/$docId.jpg",
      );
      await ref.putFile(photo!);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final firestore = FirebaseFirestore.instance;

    try {
      final docRef = await firestore.collection("passes").add({
        "type": "visitor",
        "name": _nameController.text.trim(),
        "mobile": _mobileController.text.trim(),
        "reason": _reasonController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
        "isApproved": false,
        "isEntered": false,
        "imageUrl": null,
        "addedBy": widget.guardUid,
      });

      final imageUrl = await _uploadImage(docRef.id);
      if (imageUrl != null) await docRef.update({"imageUrl": imageUrl});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Visitor registered successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error submitting visit: ${e.toString()}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  // --- UI Components ---
  Widget _input({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    final primaryColor = Colors.blue.shade700;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.black87),
      validator: (v) => v!.trim().isEmpty ? "$label required" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        fillColor: Colors.grey.shade50,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: pickImage,
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.shade50,
          border: Border.all(color: Colors.blue.shade400, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: photo != null
              ? Image.file(
                  photo!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error, size: 40, color: Colors.red),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Capture Photo',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final primaryColor = Colors.blue.shade700;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : submit,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                "Register Visitor",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Register Visitor 🚶",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _buildImagePicker()),
                  const SizedBox(height: 30),
                  _input(
                    controller: _nameController,
                    icon: Icons.person_outline,
                    label: "Visitor Name",
                  ),
                  const SizedBox(height: 18),
                  _input(
                    controller: _mobileController,
                    icon: Icons.phone_android,
                    label: "Mobile Number (10 digits)",
                    keyboard: TextInputType.phone,
                  ),
                  const SizedBox(height: 18),
                  _input(
                    controller: _reasonController,
                    icon: Icons.info_outline,
                    label: "Purpose of Visit",
                    maxLines: 3,
                  ),
                  const SizedBox(height: 30),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class RegisterVisit extends StatefulWidget {
//   final String guardUid;

//   const RegisterVisit({super.key, required this.guardUid});

//   @override
//   State<RegisterVisit> createState() => _RegisterVisitState();
// }

// class _RegisterVisitState extends State<RegisterVisit> {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController purposeController = TextEditingController();

//   bool isLoading = false;

//   Future<void> registerVisitor() async {
//     if (nameController.text.isEmpty ||
//         phoneController.text.isEmpty ||
//         purposeController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("All fields are required")),
//       );
//       return;
//     }

//     setState(() => isLoading = true);

//     try {
//       await FirebaseFirestore.instance.collection("visitor_passes").add({
//         "name": nameController.text.trim(),
//         "phone": phoneController.text.trim(),
//         "purpose": purposeController.text.trim(),
//         "guardUid": widget.guardUid,
//         "timestamp": DateTime.now(),
//         "status": "pending",
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Visitor Registered Successfully")),
//       );

//       nameController.clear();
//       phoneController.clear();
//       purposeController.clear();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e")),
//       );
//     }

//     setState(() => isLoading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Register Visitor"),
//         backgroundColor: Colors.blue,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: nameController,
//               decoration: const InputDecoration(
//                 labelText: "Visitor Name",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),

//             TextField(
//               controller: phoneController,
//               keyboardType: TextInputType.phone,
//               decoration: const InputDecoration(
//                 labelText: "Phone Number",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),

//             TextField(
//               controller: purposeController,
//               decoration: const InputDecoration(
//                 labelText: "Purpose of Visit",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),

//             isLoading
//                 ? const CircularProgressIndicator()
//                 : ElevatedButton(
//                     onPressed: registerVisitor,
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 40, vertical: 14),
//                     ),
//                     child: const Text(
//                       "Register Visitor",
//                       style: TextStyle(fontSize: 16),
//                     ),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
// }
