import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io' show HttpHeaders;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/services/cloudinary_service.dart' show CloudinaryService;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:http/http.dart' as http;

class EmployeeGatePassPage extends StatefulWidget {
  final String guardId;
    final String guardName;
  const EmployeeGatePassPage({
    super.key,
    required this.guardId,
    required this.guardName,
  });

  @override
  State<EmployeeGatePassPage> createState() => _EmployeeGatePassPageState();
}

class _EmployeeGatePassPageState extends State<EmployeeGatePassPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController employeeNameController = TextEditingController();
  final TextEditingController employeeIdController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  

  Future<String?> _uploadToCloudinary() async {
  if (_imageFile == null) return null;
  return await CloudinaryService.uploadImage(_imageFile!);
}
  File? _imageFile;
  Uint8List? _imageBytes;
  
  bool isLoading = false;

  int usedCount = 0;
  final int _monthlyLimit = 2;
  bool _loadingUsage = false;
  Timer? _debounce;

 bool get _limitReached {
  if (!_isAfter5PM) return false; // before 5 PM → no limit
  return usedCount >= _monthlyLimit; // after 5 PM → apply limit
}

  String get _monthKey {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }
  bool get _isAfter5PM {
  final now = DateTime.now();
  return now.hour >= 17; // 5 PM
}

  // ---------- FCM SERVER KEY ----------
  static const String fcmServerKey = "AIzaSyAMGZONYqaRKPxpzBqctlaDUTa-5bGM7I0"; // ⚠️ Keep secret
  //image pickup
Future<void> _pickImage(ImageSource source) async {
  if (_limitReached) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Monthly limit reached. Only $_monthlyLimit gate passes allowed.",
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  try {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: source);

    if (picked == null) return;

    if (kIsWeb) {
      _imageBytes = await picked.readAsBytes();
      _imageFile = null;
    } else {
      final file = File(picked.path);
      _imageFile = file;
      _imageBytes = await file.readAsBytes();
    }

    setState(() {});
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error picking image: $e")),
    );
  }
}

void _showImageSourceSheet() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Capture from Camera"),
              onTap: () async {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 300));
                if (!mounted) return;
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Pick from Gallery"),
              onTap: () async {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 300));
                if (!mounted) return;
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      );
    },
  );
}


 

 Future<void> _loadMonthlyCount(String empId) async {
  // 🔹 BEFORE 5 PM → skip validation
  if (!_isAfter5PM) {
    setState(() {
      usedCount = 0;
      _loadingUsage = false;
    });
    return;
  }

  final id = empId.trim();
  if (id.isEmpty) {
    setState(() => usedCount = 0);
    return;
  }

  setState(() => _loadingUsage = true);

  try {
    final q = await FirebaseFirestore.instance
        .collection("employee_gate_pass")
        .where("employeeId", isEqualTo: id)
        .where("monthKey", isEqualTo: _monthKey)
        .get();

    if (!mounted) return;
    setState(() {
      usedCount = q.size;
      _loadingUsage = false;
    });
  } catch (_) {
    if (!mounted) return;
    setState(() {
      usedCount = 0;
      _loadingUsage = false;
    });
  }
}


  void _onEmployeeIdChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadMonthlyCount(value);
    });
  }

  // ---------------- SEND FCM ----------------
  Future<void> _sendFcmNotification(String docId, String employeeName) async {
    try {
      final ownersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'owner')
          .get();

      final List<String> tokens = [];
      for (var doc in ownersSnapshot.docs) {
        final data = doc.data();
        if (data['fcmToken'] != null) tokens.add(data['fcmToken']);
      }

      if (tokens.isEmpty) return;

      final message = {
        "registration_ids": tokens,
        "notification": {
          "title": "New Employee Gate Pass",
          "body": "$employeeName has submitted a gate pass",
          "sound": "default"
        },
        "data": {
          "passId": docId,
          "type": "employee_gate_pass",
        },
      };

      final response = await http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: {
          HttpHeaders.contentTypeHeader: "application/json",
          HttpHeaders.authorizationHeader: "key=$fcmServerKey",
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print("FCM sent successfully");
      } else {
        print("FCM sending failed: ${response.body}");
      }
    } catch (e) {
      print("Error sending FCM: $e");
    }
  }

  Future<void> _submitGatePass() async {
    if (_limitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Limit reached! Only $_monthlyLimit gate passes allowed per month.",
          ),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_imageBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please capture a photo")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final String docId = DateTime.now().millisecondsSinceEpoch.toString();

      String? imageUrl;
      if (!kIsWeb) {
        try {
          imageUrl = await _uploadToCloudinary();

        } catch (e) {
          imageUrl = null;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Photo upload failed. Saving without photo.",
              ),
              backgroundColor: Colors.orange.shade700,
            ),
          );
        }
      } else {
        imageUrl = null;
      }

      await FirebaseFirestore.instance
          .collection("employee_gate_pass")
          .doc(docId)
          .set({
            "employeeId": employeeIdController.text.trim(),
            "employeeName": employeeNameController.text.trim(),
            "reason": reasonController.text.trim(),
            "guardId": widget.guardId,
            "createdAt": Timestamp.now(),
            "monthKey": _monthKey,
            "status": "approved",
            "imageUrl": imageUrl,
          });

      // Send FCM to all owners
      await _sendFcmNotification(docId, employeeNameController.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gate pass submitted successfully"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error submitting: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildUsageBanner() {
final text = !_isAfter5PM
    ? "No limit before 5:00 PM"
    : _loadingUsage
        ? "Checking usage..."
        : "Used this month: $usedCount / $_monthlyLimit";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBox() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.shade700),
          color: Colors.grey.shade200,
        ),
        child: _imageBytes == null
            ? const Center(child: Text("Tap to capture photo"))
            : (kIsWeb
                ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                : Image.file(_imageFile!, fit: BoxFit.cover)),
      ),
    );
  }

 Widget _buildSubmitButton() {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: isLoading ? null : _submitGatePass,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.shade700,
        padding: const EdgeInsets.all(14),
      ),
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white, // ✅ visible on purple
              ),
            )
          : const Text(
              "Submit Gate Pass",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
  "Employee Gate Pass",
  style: const TextStyle(
    color: Colors.white,
  ),
),
        backgroundColor: Colors.orange.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildUsageBanner(),
              const SizedBox(height: 20),
              TextFormField(
                controller: employeeNameController,
                decoration: const InputDecoration(
                  labelText: "Employee Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? "Enter employee name"
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: employeeIdController,
                onChanged: _onEmployeeIdChanged,
                decoration: const InputDecoration(
                  labelText: "Employee ID",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Enter Employee ID" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Reason",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Enter reason" : null,
              ),
              const SizedBox(height: 20),
              _buildPhotoBox(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    employeeNameController.dispose();
    employeeIdController.dispose();
    reasonController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
