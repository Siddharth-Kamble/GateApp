import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart';

class RegisterVehicle extends StatefulWidget {
  const RegisterVehicle({super.key});

  @override
  State<RegisterVehicle> createState() => _RegisterVehicleState();
}

class _RegisterVehicleState extends State<RegisterVehicle> {
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  File? _photo;
  final TextEditingController _vehicleNumberController =
      TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  String _vehicleType = "Two Wheeler";

  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _ownerNameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource src) async {
    final picked = await _picker.pickImage(source: src);
    if (picked != null) {
      setState(() => _photo = File(picked.path));
    }
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pick from Gallery'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Open Camera'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage(String id) async {
    if (_photo == null) return null;

    try {
      final ref = _storage.ref("vehicles/$id.jpg");
      await ref.putFile(_photo!);
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) print("Image upload error: $e");
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Replace AppConfig usage with direct Firebase check
    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Firebase not initialized."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must be logged in."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _firestore.enableNetwork();

      // 1. Add base data first
      final docRef = await _firestore.collection("vehicles").add({
        "vehicleNumber": _vehicleNumberController.text.trim(),
        "ownerName": _ownerNameController.text.trim(),
        "contact": _contactController.text.trim(),
        "vehicleType": _vehicleType,
        "createdAt": FieldValue.serverTimestamp(),

        // Approval Flow
        "status": "pending",
        "submittedBy": user.uid,
        "approvedBy": null,
        "approvedAt": null,

        // Image
        "photoUrl": null,
      });

      // 2. Upload Image
      final url = await _uploadImage(docRef.id);

      if (url != null) {
        await docRef.update({"photoUrl": url});
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vehicle registered successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red),
        );
      }
      if (kDebugMode) print('vehicle registration failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Local replacement for your missing makeButton(...) helper
  Widget _buildSubmitButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register Vehicle"),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showPicker,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _photo != null
                          ? FileImage(_photo!)
                          : null,
                      child: _photo == null
                          ? const Icon(Icons.camera_alt, size: 32)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Number
                  TextFormField(
                    controller: _vehicleNumberController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.confirmation_number),
                      labelText: "Vehicle Number",
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),

                  // Owner Name
                  TextFormField(
                    controller: _ownerNameController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      labelText: "Owner Name",
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),

                  // Contact Number
                  TextFormField(
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.phone),
                      labelText: "Contact Number",
                    ),
                    validator: (v) => (v == null || v.trim().length != 10)
                        ? "Enter valid 10-digit number"
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _vehicleType,
                    items: const [
                      DropdownMenuItem(
                        value: "Two Wheeler",
                        child: Text("Two Wheeler"),
                      ),
                      DropdownMenuItem(
                        value: "Four Wheeler",
                        child: Text("Four Wheeler"),
                      ),
                      DropdownMenuItem(value: "Truck", child: Text("Truck")),
                    ],
                    onChanged: (v) => setState(() => _vehicleType = v!),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Use local button helper (or replace with your makeButton)
                  _buildSubmitButton(
                    _isSubmitting ? "Submitting..." : "Register Vehicle",
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
}
