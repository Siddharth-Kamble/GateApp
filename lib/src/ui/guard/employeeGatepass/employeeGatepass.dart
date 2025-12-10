// import 'dart:async';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';

// class EmployeeGatePassPage extends StatefulWidget {
//   final String guardId;
//   const EmployeeGatePassPage({super.key, required this.guardId});

//   @override
//   State<EmployeeGatePassPage> createState() => _EmployeeGatePassPageState();
// }

// class _EmployeeGatePassPageState extends State<EmployeeGatePassPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController employeeNameController = TextEditingController();
//   final TextEditingController employeeIdController = TextEditingController();
//   final TextEditingController reasonController = TextEditingController();

//   File? _imageFile;         // Android / iOS
//   Uint8List? _imageBytes;   // Web + upload source

//   bool isLoading = false;

//   // ------------- MONTHLY LIMIT -------------
//   int usedCount = 0;
//   final int _monthlyLimit = 2;
//   bool _loadingUsage = false;
//   Timer? _debounce;

//   bool get _limitReached => usedCount >= _monthlyLimit;

//   String get _monthKey {
//     final now = DateTime.now();
//     return "${now.year}-${now.month.toString().padLeft(2, '0')}";
//   }

//   // ------------- PICK IMAGE -------------
//   Future<void> _pickImage() async {
//     if (_limitReached) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//               "Monthly limit reached. Only $_monthlyLimit gate passes allowed."),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     try {
//       final picker = ImagePicker();
//       final XFile? picked =
//           await picker.pickImage(source: ImageSource.camera);

//       if (picked == null) return;

//       if (kIsWeb) {
//         _imageBytes = await picked.readAsBytes();
//         _imageFile = null;
//       } else {
//         final file = File(picked.path);
//         _imageFile = file;
//         _imageBytes = await file.readAsBytes();
//       }

//       setState(() {});
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error picking image: $e")),
//       );
//     }
//   }

//   // ------------- UPLOAD IMAGE (MOBILE ONLY) -------------
//   Future<String> _uploadImage(Uint8List bytes) async {
//     final fileName =
//         "employee_gate_pass/${DateTime.now().millisecondsSinceEpoch}.jpg";

//     final ref = FirebaseStorage.instance.ref().child(fileName);
//     await ref.putData(bytes, SettableMetadata(contentType: "image/jpeg"));
//     return await ref.getDownloadURL();
//   }

//   // ------------- LOAD MONTHLY COUNT -------------
//   Future<void> _loadMonthlyCount(String empId) async {
//     final id = empId.trim();
//     if (id.isEmpty) {
//       setState(() => usedCount = 0);
//       return;
//     }

//     setState(() => _loadingUsage = true);

//     try {
//       final q = await FirebaseFirestore.instance
//           .collection("employee_gate_pass")
//           .where("employeeId", isEqualTo: id)
//           .where("monthKey", isEqualTo: _monthKey)
//           .get();

//       if (!mounted) return;
//       setState(() {
//         usedCount = q.size;
//         _loadingUsage = false;
//       });
//     } catch (_) {
//       if (!mounted) return;
//       setState(() {
//         usedCount = 0;
//         _loadingUsage = false;
//       });
//     }
//   }

//   void _onEmployeeIdChanged(String value) {
//     _debounce?.cancel();
//     _debounce = Timer(const Duration(milliseconds: 500), () {
//       _loadMonthlyCount(value);
//     });
//   }

//   // ------------- SUBMIT GATE PASS -------------
//   Future<void> _submitGatePass() async {
//     if (_limitReached) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//               "Limit reached! Only $_monthlyLimit gate passes allowed per month."),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     if (!_formKey.currentState!.validate()) return;

//     if (_imageBytes == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please capture a photo")),
//       );
//       return;
//     }

//     setState(() => isLoading = true);

//     try {
//       final String docId =
//           DateTime.now().millisecondsSinceEpoch.toString();

//       String? imageUrl;

//       // ⚠️ Web me CORS issue hai, isliye upload SKIP kar rahe hain
//       // Android / iOS me upload karenge
//       if (!kIsWeb) {
//         try {
//           imageUrl = await _uploadImage(_imageBytes!);
//         } catch (e) {
//           imageUrl = null;
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                   "Photo upload failed (Storage issue). Saving without photo."),
//               backgroundColor: Colors.orange,
//             ),
//           );
//         }
//       } else {
//         imageUrl = null; // Web: only icon show karega, photo upload nahi
//       }

//       await FirebaseFirestore.instance
//           .collection("employee_gate_pass")
//           .doc(docId)
//           .set({
//         "employeeId": employeeIdController.text.trim(),
//         "employeeName": employeeNameController.text.trim(),
//         "reason": reasonController.text.trim(),
//         "guardId": widget.guardId,
//         "createdAt": Timestamp.now(),
//         "monthKey": _monthKey,
//         "status": "approved",
//         "imageUrl": imageUrl, // mobile par URL, web par null
//       });

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Gate pass submitted successfully"),
//           backgroundColor: Colors.green,
//         ),
//       );
//       Navigator.pop(context);
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error submitting: $e")),
//       );
//     } finally {
//       if (mounted) setState(() => isLoading = false);
//     }
//   }

//   // ------------- UI HELPERS -------------

//   Widget _buildUsageBanner() {
//     final text = _loadingUsage
//         ? "Checking usage..."
//         : "Used this month: $usedCount / $_monthlyLimit";

//     return Container(
//       padding:
//           const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade50,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.info_outline, color: Colors.blue),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(
//                   fontWeight: FontWeight.bold, fontSize: 15),
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildPhotoBox() {
//     return GestureDetector(
//       onTap: _pickImage,
//       child: Container(
//         height: 180,
//         width: double.infinity,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: Colors.deepPurple),
//           color: Colors.grey.shade200,
//         ),
//         child: _imageBytes == null
//             ? const Center(child: Text("Tap to capture photo"))
//             : (kIsWeb
//                 ? Image.memory(_imageBytes!, fit: BoxFit.cover)
//                 : Image.file(_imageFile!, fit: BoxFit.cover)),
//       ),
//     );
//   }

//   Widget _buildSubmitButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: isLoading ? null : _submitGatePass,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.deepPurple,
//           padding: const EdgeInsets.all(14),
//         ),
//         child: isLoading
//             ? const CircularProgressIndicator(color: Colors.white)
//             : const Text(
//                 "Submit Gate Pass",
//                 style: TextStyle(fontSize: 18, color: Colors.white),
//               ),
//       ),
//     );
//   }

//   // ------------- BUILD -------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Employee Gate Pass"),
//         backgroundColor: Colors.deepPurple,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               _buildUsageBanner(),
//               const SizedBox(height: 20),

//               TextFormField(
//                 controller: employeeNameController,
//                 decoration: const InputDecoration(
//                   labelText: "Employee Name",
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (v) =>
//                     v == null || v.trim().isEmpty ? "Enter employee name" : null,
//               ),
//               const SizedBox(height: 16),

//               TextFormField(
//                 controller: employeeIdController,
//                 onChanged: _onEmployeeIdChanged,
//                 decoration: const InputDecoration(
//                   labelText: "Employee ID",
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (v) =>
//                     v == null || v.trim().isEmpty ? "Enter Employee ID" : null,
//               ),
//               const SizedBox(height: 16),

//               TextFormField(
//                 controller: reasonController,
//                 maxLines: 3,
//                 decoration: const InputDecoration(
//                   labelText: "Reason",
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (v) =>
//                     v == null || v.trim().isEmpty ? "Enter reason" : null,
//               ),
//               const SizedBox(height: 20),

//               _buildPhotoBox(),
//               const SizedBox(height: 30),

//               _buildSubmitButton(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     employeeNameController.dispose();
//     employeeIdController.dispose();
//     reasonController.dispose();
//     _debounce?.cancel();
//     super.dispose();
//   }
// }
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EmployeeGatePassPage extends StatefulWidget {
  final String guardId;
  const EmployeeGatePassPage({super.key, required this.guardId});

  @override
  State<EmployeeGatePassPage> createState() => _EmployeeGatePassPageState();
}

class _EmployeeGatePassPageState extends State<EmployeeGatePassPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController employeeNameController = TextEditingController();
  final TextEditingController employeeIdController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  File? _imageFile;
  Uint8List? _imageBytes;

  bool isLoading = false;

  int usedCount = 0;
  final int _monthlyLimit = 2;
  bool _loadingUsage = false;
  Timer? _debounce;

  bool get _limitReached => usedCount >= _monthlyLimit;

  String get _monthKey {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  Future<void> _pickImage() async {
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
      final XFile? picked = await picker.pickImage(source: ImageSource.camera);

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error picking image: $e")));
    }
  }

  Future<String> _uploadImage(Uint8List bytes) async {
    final fileName =
        "employee_gate_pass/${DateTime.now().millisecondsSinceEpoch}.jpg";

    final ref = FirebaseStorage.instance.ref().child(fileName);
    await ref.putData(bytes, SettableMetadata(contentType: "image/jpeg"));
    return await ref.getDownloadURL();
  }

  Future<void> _loadMonthlyCount(String empId) async {
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

  Future<void> _submitGatePass() async {
    if (_limitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Limit reached! Only $_monthlyLimit gate passes allowed per month.",
          ),
          backgroundColor: Colors.red,
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
          imageUrl = await _uploadImage(_imageBytes!);
        } catch (e) {
          imageUrl = null;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Photo upload failed (Storage issue). Saving without photo.",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        imageUrl = null;
      }

      // ✅ Automatically fetch the first ownerId from users collection
      String ownerId = "";
      final ownerSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'owner')
          .limit(1)
          .get();
      if (ownerSnapshot.docs.isNotEmpty) {
        ownerId = ownerSnapshot.docs.first.id;
      }

      await FirebaseFirestore.instance
          .collection("employee_gate_pass")
          .doc(docId)
          .set({
            "employeeId": employeeIdController.text.trim(),
            "employeeName": employeeNameController.text.trim(),
            "reason": reasonController.text.trim(),
            "guardId": widget.guardId,
            "ownerId": ownerId, // ✅ Added ownerId for automatic notification
            "createdAt": Timestamp.now(),
            "monthKey": _monthKey,
            "status": "approved",
            "imageUrl": imageUrl,
          });

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
    final text = _loadingUsage
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
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.deepPurple),
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
          backgroundColor: Colors.deepPurple,
          padding: const EdgeInsets.all(14),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
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
        title: const Text("Employee Gate Pass"),
        backgroundColor: Colors.deepPurple,
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
