import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/models/user_model.dart'
    show UserModel;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class RegisterVehicle extends StatefulWidget {
  final UserModel loggedInGuard;

  const RegisterVehicle({super.key, required this.loggedInGuard});

  @override
  State<RegisterVehicle> createState() => _RegisterVehicleState();
}

class _RegisterVehicleState extends State<RegisterVehicle> {
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  File? _photo;
  Uint8List? _photoBytes;

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

  // ---------------- IMAGE PICKING ----------------
  Future<void> _pickImage(ImageSource src) async {
    final picked = await _picker.pickImage(source: src);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _photoBytes = bytes;
        _photo = null;
      });
    } else {
      setState(() {
        _photo = File(picked.path);
        _photoBytes = null;
      });
    }
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Container(
                height: 5,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.indigo),
              title: const Text('Pick from Gallery'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.indigo),
              title: const Text('Open Camera'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ---------------- FIREBASE STORAGE ----------------
  Future<String?> _uploadImage(String id) async {
    if (!kIsWeb && _photo == null) return null;
    if (kIsWeb && _photoBytes == null) return null;

    try {
      final ref = _storage.ref("vehicles_photos/$id.jpg");

      if (kIsWeb) {
        await ref.putData(_photoBytes!);
      } else {
        await ref.putFile(_photo!);
      }

      return await ref.getDownloadURL();
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  // ---------------- FIRESTORE SUBMISSION ----------------
  Future<void> _submitToFirestore() async {
    setState(() => _isSubmitting = true);

    try {
      // Save guard-registered vehicles in 'passes' so OwnerDashboard can see them
      final docRef = await _firestore.collection("passes").add({
        "type": "vehicle",
        "ownerName": _ownerNameController.text.trim(),
        "contact": _contactController.text.trim(),
        "vehicleNumber": _vehicleNumberController.text.trim(),
        "vehicleType": _vehicleType,
        "status": "pending", // default status
        "isEntered": false,
        "createdAt": FieldValue.serverTimestamp(),
        "registeredByGuard": widget.loggedInGuard.uid,
        "guardName": widget.loggedInGuard.name,
        "photoUrl": null,
      });

      // upload image
      final url = await _uploadImage(docRef.id);
      if (url != null) await docRef.update({"photoUrl": url});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Vehicle registered successfully!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Failed: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _submitToFirestore();
  }

  // ---------------- UI HELPERS ----------------
  Widget _buildSubmitButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.indigo.shade600,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: (_isSubmitting)
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.indigo.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.indigo.shade600, width: 2),
        ),
        fillColor: Colors.grey.shade50,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 10,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showPicker,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.indigo.shade50,
          border: Border.all(color: Colors.indigo.shade400, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: Builder(
            builder: (context) {
              if (kIsWeb && _photoBytes != null) {
                return Image.memory(_photoBytes!, fit: BoxFit.cover);
              }
              if (!kIsWeb && _photo != null) {
                return Image.file(_photo!, fit: BoxFit.cover);
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 36,
                      color: Colors.indigo.shade700,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add Photo',
                      style: TextStyle(
                        color: Colors.indigo.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      initialValue: _vehicleType,
      items: const [
        DropdownMenuItem(value: "Two Wheeler", child: Text("Two Wheeler")),
        DropdownMenuItem(value: "Four Wheeler", child: Text("Four Wheeler")),
        DropdownMenuItem(value: "Truck", child: Text("Truck")),
      ],
      onChanged: (v) => setState(() => _vehicleType = v!),
      decoration: InputDecoration(
        labelText: "Vehicle Type",
        prefixIcon: Icon(Icons.directions_car, color: Colors.indigo.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.indigo.shade600, width: 2),
        ),
        filled: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Vehicle Registration 🚗",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Provide vehicle and owner details.",
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: _buildImagePicker()),
                      const SizedBox(height: 24),
                      const Divider(height: 1, color: Colors.grey),
                      const SizedBox(height: 24),
                      _buildInputField(
                        controller: _vehicleNumberController,
                        labelText: "Vehicle Number (e.g., MH12AB1234)",
                        icon: Icons.confirmation_number_rounded,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _ownerNameController,
                        labelText: "Owner Name",
                        icon: Icons.person_outline,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _contactController,
                        labelText: "Contact Number",
                        icon: Icons.phone_android,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().length != 10)
                            ? "Enter valid 10-digit number"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(),
                      const SizedBox(height: 30),
                      _buildSubmitButton("Register Vehicle", _submit),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
