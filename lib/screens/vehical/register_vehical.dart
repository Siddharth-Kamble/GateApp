import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
// uuid not required currently
import 'package:vms/components/button.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../config/app_config.dart';

class RegisterVehical extends StatefulWidget {
  const RegisterVehical({Key? key}) : super(key: key);

  @override
  State<RegisterVehical> createState() => _RegisterVehicalState();
}

class _RegisterVehicalState extends State<RegisterVehical> {
  final firebase_storage.FirebaseStorage _storage =
      firebase_storage.FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  File? _photo;
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  String _vehicleType = 'Two Wheeler';
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
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _uploadImage(String id) async {
    if (_photo == null) return;
    try {
      await _storage.ref(id).putFile(_photo!);
    } catch (e) {
      if (kDebugMode) print('vehicle image upload failed: $e');
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
              title: const Text('Gallery'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Ensure Firebase is available before attempting network operations
    if (!AppConfig.firebaseAvailable || Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot submit: network/Firebase unavailable'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Ensure Firestore network is enabled before attempting write
      try {
        await _firestore.enableNetwork();
      } catch (_) {}

      final docRef = await _firestore.collection('vehicles').add({
        'vehicleNumber': _vehicleNumberController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'contact': _contactController.text.trim(),
        'vehicleType': _vehicleType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _uploadImage(docRef.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle registered successfully'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to register vehicle'), backgroundColor: Colors.red),
        );
      }
      if (kDebugMode) print('vehicle registration failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Vehicle'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _showPicker,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _photo != null ? FileImage(_photo!) : null,
                      child: _photo == null ? const Icon(Icons.camera_alt) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vehicleNumberController,
                    decoration: InputDecoration(labelText: 'Vehicle Number', prefixIcon: const Icon(Icons.confirmation_number)),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Vehicle number required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ownerNameController,
                    decoration: InputDecoration(labelText: 'Owner Name', prefixIcon: const Icon(Icons.person)),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Owner name required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: 'Contact Number', prefixIcon: const Icon(Icons.phone)),
                    validator: (v) => (v == null || v.trim().length != 10) ? 'Enter valid 10 digit contact' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _vehicleType,
                    items: const [
                      DropdownMenuItem(value: 'Two Wheeler', child: Text('Two Wheeler')),
                      DropdownMenuItem(value: 'Four Wheeler', child: Text('Four Wheeler')),
                      DropdownMenuItem(value: 'Truck', child: Text('Truck')),
                    ],
                    onChanged: (v) => setState(() => _vehicleType = v ?? 'Two Wheeler'),
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.directions_car)),
                  ),
                  const SizedBox(height: 20),
                  makeButton(_isSubmitting ? 'Submitting...' : 'Register Vehicle', _isSubmitting ? null : _submit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
