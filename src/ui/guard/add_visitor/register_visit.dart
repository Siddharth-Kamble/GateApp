import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';

class RegisterVisit extends StatefulWidget {
  const RegisterVisit({super.key});

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

  Future<void> pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.camera);
    if (img != null) {
      setState(() => photo = File(img.path));
    }
  }

  Future<String?> uploadImage(String docId) async {
    if (photo == null) return null;

    try {
      final ref = firebase_storage.FirebaseStorage.instance.ref().child(
        "visitor_photos/$docId.jpg",
      );

      await ref.putFile(photo!);
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) print("Image upload failed: $e");
      return null;
    }
  }

  // ----------------- SUBMIT ------------------
  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Guard must be logged in"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      // Create visitor request
      final docRef = await firestore.collection("passes").add({
        "type": "visitor",
        "name": _nameController.text.trim(),
        "mobile": _mobileController.text.trim(),
        "reason": _reasonController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
        "isApproved": false, // OWNER APPROVES THIS
        "isEntered": false, // GUARD ALLOWS ENTRY
        "imageUrl": null,
        "addedBy": user.uid, // which guard added this
      });

      // Upload image
      final imageUrl = await uploadImage(docRef.id);

      if (imageUrl != null) {
        await docRef.update({"imageUrl": imageUrl});
      }

      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Visitor registered successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // go back to Guard Dashboard
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }

    setState(() => _isSubmitting = false);
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Register Visitor"),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Pick Image
                  GestureDetector(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: photo != null ? FileImage(photo!) : null,
                      child: photo == null
                          ? const Icon(Icons.camera_alt, size: 35)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Name
                  _input(
                    controller: _nameController,
                    icon: Icons.person,
                    label: "Visitor Name",
                    validator: (v) =>
                        v!.trim().isEmpty ? "Name cannot be empty" : null,
                  ),
                  const SizedBox(height: 16),

                  // Mobile
                  _input(
                    controller: _mobileController,
                    icon: Icons.phone,
                    label: "Mobile Number",
                    keyboard: TextInputType.phone,
                    validator: (v) => !RegExp(r'^\d{10}$').hasMatch(v!)
                        ? "Enter valid 10 digit number"
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Reason
                  _input(
                    controller: _reasonController,
                    icon: Icons.info_outline,
                    label: "Visit Reason",
                    maxLines: 3,
                    validator: (v) =>
                        v!.trim().isEmpty ? "Reason required" : null,
                  ),

                  const SizedBox(height: 22),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : submit,
                      child: Text(
                        _isSubmitting ? "Submitting..." : "Submit",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Reusable input field
  Widget _input({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
