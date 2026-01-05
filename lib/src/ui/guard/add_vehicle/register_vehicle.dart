import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/models/user_model.dart';
import 'package:flutter_application_1/src/services/cloudinary_service.dart'
    show CloudinaryService;
import 'package:flutter_image_compress/flutter_image_compress.dart' show CompressFormat, FlutterImageCompress;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;

class RegisterVehicle extends StatefulWidget {
  final UserModel loggedInGuard;

  const RegisterVehicle({super.key, required this.loggedInGuard});

  @override
  State<RegisterVehicle> createState() => _RegisterVehicleState();
}

class _RegisterVehicleState extends State<RegisterVehicle> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  File? _frontPhoto;
  File? _backPhoto;

  Uint8List? _frontPhotoBytes;
  Uint8List? _backPhotoBytes;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _vehicleNumberController =
      TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _kmReadingController = TextEditingController();

  String _vehicleType = "Two Wheeler";

  bool _isSubmitting = false;

  static const String _backendUrl =
      'https://fcm-server-s0z6.onrender.com/notify-owner';
  static const String _companyOwnerId = "iDyPReum390W77oiFJhp";

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _driverNameController.dispose();
    _contactController.dispose();
    _kmReadingController.dispose();

    super.dispose();
  }

   Future<File> _compressImageUnder100KB(File file) async {
    final dir = await getTemporaryDirectory();

    int quality = 85;
    Uint8List? result;

    do {
      final targetPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressed =
          await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        minWidth: 1080,
        minHeight: 1080,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (compressed == null) {
        throw Exception('Image compression failed');
      }

      result = await compressed.readAsBytes();
      quality -= 5;
    } while (result.lengthInBytes > 100 * 1024 && quality >= 20);

    if (result.lengthInBytes > 100 * 1024) {
      throw Exception('Unable to compress image below 100 KB');
    }

    final finalFile = File(
      '${dir.path}/final_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await finalFile.writeAsBytes(result, flush: true);
    return finalFile;
  }


  // ---------------- IMAGE PICK ----------------
  Future<void> _pickImage(ImageSource src, bool isFront) async {
    final picked = await _picker.pickImage(source: src);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      if (isFront) {
        _frontPhotoBytes = bytes;
        _frontPhoto = null;
      } else {
        _backPhotoBytes = bytes;
        _backPhoto = null;
      }
    } else {
      final file = File(picked.path);
      if (isFront) {
        _frontPhoto = file;
        _frontPhotoBytes = null;
      } else {
        _backPhoto = file;
        _backPhotoBytes = null;
      }
    }

    setState(() {});
  }
  Future<void> _pickFromSource(ImageSource source, bool isFront) async {
  final picked = await _picker.pickImage(source: source);
  if (picked == null) return;

  if (kIsWeb) {
    final bytes = await picked.readAsBytes();
    if (isFront) {
      _frontPhotoBytes = bytes;
      _frontPhoto = null;
    } else {
      _backPhotoBytes = bytes;
      _backPhoto = null;
    }
  } else {
    final file = File(picked.path);
    if (isFront) {
      _frontPhoto = file;
      _frontPhotoBytes = null;
    } else {
      _backPhoto = file;
      _backPhotoBytes = null;
    }
  }

  if (mounted) {
    setState(() {});
  }
}


  void _showPicker(bool isFront) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Camera"),
            onTap: () async {
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 300));
              if (!mounted) return;
              _pickFromSource(ImageSource.camera, isFront);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Gallery"),
            onTap: () async {
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 300));
              if (!mounted) return;
              _pickFromSource(ImageSource.gallery, isFront);
            },
          ),
        ],
      ),
    ),
  );
}


  // ---------------- UPLOAD IMAGE ----------------

  // ---------------- NOTIFY OWNER ----------------
  Future<void> _notifyOwner(String passId) async {
    await http.post(
      Uri.parse(_backendUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "ownerId": _companyOwnerId,
        "passId": passId,
        "type": "vehicle",
      }),
    );
  }

  // ---------------- SUBMIT ----------------
  Future<void> _submit() async {
    // 1️⃣ Validate form
    if (!_formKey.currentState!.validate()) return;

    // 2️⃣ Check image selected
    if ((_frontPhoto == null && _frontPhotoBytes == null) ||
        (_backPhoto == null && _backPhotoBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add both front and back images")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? frontImageUrl;
String? backImageUrl;

if (kIsWeb) {
  frontImageUrl =
      await CloudinaryService.uploadImageBytes(_frontPhotoBytes!);
  backImageUrl =
      await CloudinaryService.uploadImageBytes(_backPhotoBytes!);
} else {
 final compressedFront =
    await _compressImageUnder100KB(_frontPhoto!);
final compressedBack =
    await _compressImageUnder100KB(_backPhoto!);

  frontImageUrl =
      await CloudinaryService.uploadImage(compressedFront);
  backImageUrl =
      await CloudinaryService.uploadImage(compressedBack);
}

if (frontImageUrl == null || backImageUrl == null) {
  throw Exception('Image upload failed');
}


      final kmText = _kmReadingController.text.trim();
      // 4️⃣ Save data to Firestore
      final docRef = await _firestore.collection("passes").add({
        "type": "vehicle",
        "driverName": _driverNameController.text.trim(),
        "contact": _contactController.text.trim(),
        "vehicleNumber": _vehicleNumberController.text.trim(),
        "kmReading": int.tryParse(kmText),
        "vehicleType": _vehicleType,

        "status": "pending",
        "isEntered": false,
        "isExited": false,
        "isApproved": false,

        "notificationSent": false,
        "createdAt": FieldValue.serverTimestamp(),
        "registeredByGuard": widget.loggedInGuard.uid,
        "guardName": widget.loggedInGuard.name,
        "frontImageUrl": frontImageUrl,
        "backImageUrl": backImageUrl,
      });

      // 5️⃣ Notify owner (UNCHANGED)
      await _notifyOwner(docRef.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vehicle registered successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ---------------- INPUT ----------------
  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Vehicle Registration"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // IMAGE
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // FRONT IMAGE
                          GestureDetector(
                            onTap: () => _showPicker(true), // ✅ FIXED
                            child: Column(
                              children: [
                                Container(
                                  height: 120,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.blue.shade700,
                                      width: 1.5,
                                    ),
                                    color: Colors.blue.shade50,
                                  ),
                                  child: _frontPhotoBytes != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Image.memory(
                                            _frontPhotoBytes!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : _frontPhoto != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Image.file(
                                            _frontPhoto!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          size: 40,
                                          color: Colors.blue,
                                        ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Front",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),

                          // BACK IMAGE
                          GestureDetector(
                            onTap: () => _showPicker(false), // ✅ FIXED
                            child: Column(
                              children: [
                                Container(
                                  height: 120,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.blue.shade700,
                                      width: 1.5,
                                    ),
                                    color: Colors.blue.shade50,
                                  ),
                                  child: _backPhotoBytes != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Image.memory(
                                            _backPhotoBytes!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : _backPhoto != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Image.file(
                                            _backPhoto!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          size: 40,
                                          color: Colors.blue,
                                        ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Back",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // FORM
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _input(
                        controller: _vehicleNumberController,
                        label: "Vehicle Number",
                        icon: Icons.confirmation_number,
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      _input(
                        controller: _driverNameController,
                        label: "Driver Name",
                        icon: Icons.person,
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      _input(
                        controller: _kmReadingController,
                        label: "Vehicle KM Reading",
                        icon: Icons.speed,
                        validator: (v) {
                          if (v == null || v.isEmpty) return null; // optional
                          if (int.tryParse(v) == null)
                            return "Enter valid number";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _input(
                        controller: _contactController,
                        label: "Contact Number",
                        icon: Icons.phone,
                        validator: (v) {
                          if (v == null || v.isEmpty) return null; // optional
                          if (v.length != 10) return "Invalid number";
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // MOVEMENT
                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        value: _vehicleType,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Type',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: "Two Wheeler",
                            child: Row(
                              children: [
                                Icon(Icons.two_wheeler, size: 20),
                                SizedBox(width: 8),
                                Text("Two Wheeler"),
                              ],
                            ),
                          ),
                          const DropdownMenuItem(
                            value: "Four Wheeler",
                            child: Row(
                              children: [
                                Icon(Icons.directions_car, size: 20),
                                SizedBox(width: 8),
                                Text("Four Wheeler"),
                              ],
                            ),
                          ),
                          const DropdownMenuItem(
                            value: "Auto Rickshaw",
                            child: Row(
                              children: [
                                Icon(Icons.electric_rickshaw, size: 20), // 🛺
                                SizedBox(width: 8),
                                Text("Auto Rickshaw"),
                              ],
                            ),
                          ),
                          const DropdownMenuItem(
                            value: "Truck",
                            child: Row(
                              children: [
                                Icon(Icons.local_shipping, size: 20),
                                SizedBox(width: 8),
                                Text("Truck"),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: "JCB",
                            child: Row(
                              children: [
                                // Display the JCB image from network (URL)
                                Image.asset(
                                  'lib/src/assets/jcb.jpg', // Path to your JCB icon image
                                  width: 20, // Adjust the width
                                  height: 20, // Adjust the height
                                ),
                                SizedBox(width: 8),
                                Text("JCB"),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _vehicleType = v!);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Register Vehicle",
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

  Widget _imageBox({
    required String title,
    File? file,
    Uint8List? bytes,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade700),
              color: Colors.blue.shade50,
            ),
            child: bytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  )
                : file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(file, fit: BoxFit.cover),
                  )
                : const Icon(Icons.camera_alt, size: 32),
          ),
        ),
        const SizedBox(height: 6),
        Text(title),
      ],
    );
  }
}
