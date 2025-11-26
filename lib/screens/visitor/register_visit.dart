import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vms/components/button.dart';
import 'package:vms/model/pass_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../config/app_config.dart';
import 'package:uuid/uuid.dart';
import 'package:vms/screens/visitor/pass_screen.dart';

class RegisterVisit extends StatefulWidget {
  const RegisterVisit({Key? key}) : super(key: key);

  @override
  State<RegisterVisit> createState() => _RegisterVisitState();
}

class _RegisterVisitState extends State<RegisterVisit> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  final _formKey = GlobalKey<FormState>();

  File? photo;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> pickImage(ImageSource src) async {
    final image = await _picker.pickImage(source: src);
    if (image != null) {
      setState(() => photo = File(image.path));
    }
  }

  Future<void> uploadImage(String id) async {
    if (photo == null) return;
    try {
      await storage.ref(id).putFile(photo!);
    } catch (e) {
      if (kDebugMode) print('Error uploading image: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

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
                  // image
                  GestureDetector(
                    onTap: () => pickImage(ImageSource.camera),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          photo != null ? FileImage(photo!) : null,
                      child: photo == null
                          ? const Icon(Icons.camera_alt, size: 35)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Name field
                  _input(
                    controller: _nameController,
                    icon: Icons.person,
                    label: "Name",
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return "Name cannot be empty";
                      if (value.length < 3) {
                        return "Name must be at least 3 characters";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Mobile
                  _input(
                    controller: _mobileController,
                    icon: Icons.phone,
                    label: "Mobile Number",
                    keyboard: TextInputType.phone,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return "Mobile number is required";
                      if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                        return "Enter valid 10 digit number";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Visit reason
                  _input(
                    controller: _reasonController,
                    icon: Icons.info_outline,
                    label: "Visit Reason",
                    maxLines: 3,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? "Required" : null,
                  ),

                  const SizedBox(height: 24),

                  makeButton(
                    _isSubmitting ? "Submitting..." : "Submit",
                    _isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

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
      decoration: _decor(label, icon),
    );
  }

  // ---------- SUBMIT ----------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Ensure Firebase is available before attempting network operations
    if (!AppConfig.firebaseAvailable || Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot submit: Firebase is not initialized.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create a pass.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final firestore = FirebaseFirestore.instance;

    final pass = PassModel();
    const uuid = Uuid();
    pass.passSecret = uuid.v1();
    pass.userId = user.uid;
    pass.email = user.email;
    pass.name = _nameController.text.trim();
    pass.contactInfo = _mobileController.text.trim();
    pass.location = _reasonController.text.trim(); // visit reason
    pass.isActive = false;
    pass.isVerified = false;

    try {
      // Map + createdAt for Today Activity
      final data = pass.toMap();
      data["createdAt"] = FieldValue.serverTimestamp();

      // Make sure network is on (in case it was disabled earlier)
      try {
        await firestore.enableNetwork();
      } catch (_) {
        // ignore – if it fails, Firestore will throw below anyway
      }

      // Create pass document
      final doc = await firestore.collection("passes").add(data);
      pass.uid = doc.id;

      // Upload visitor photo (if any)
      await uploadImage(pass.uid!);

      // Update user doc with this pass id
      await firestore.collection("users").doc(user.uid).update({
        "passes": FieldValue.arrayUnion([pass.uid!]),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pass created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PassScreen(pass),
        ),
      );
    } on FirebaseException catch (e) {
      if (mounted) {
        String message = 'Failed to create pass.';
        if (e.code == 'unavailable') {
          message =
              'Cannot reach server (offline). Check your internet / firewall.';
        } else if (e.message != null) {
          message = e.message!;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
      if (kDebugMode) print('FirebaseException creating pass: $e');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (kDebugMode) print('Error creating pass: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
