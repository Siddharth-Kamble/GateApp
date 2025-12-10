// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/src/ui/guard/GuardRequestpage.dart'
//     show GuardRequestStatusPage, EntryType;
// import '../../services/DataService.dart' show DataService;

// // --- Constants ---
// const Color primaryGuardColor = Color(0xFF00ACC1);
// const Color faintBackground = Color(0xFFF9F9FB);

// class VisitorEntryPage extends StatefulWidget {
//   const VisitorEntryPage({super.key});

//   @override
//   State<VisitorEntryPage> createState() => _VisitorEntryPageState();
// }

// class _VisitorEntryPageState extends State<VisitorEntryPage> {
//   final _formKey = GlobalKey<FormState>();
//   final DataService _dataService = DataService();

//   final _nameController = TextEditingController();
//   final _mobileController = TextEditingController();
//   final _otpController = TextEditingController();

//   String? _selectedPurpose;
//   bool _otpSent = false;
//   bool _isVerified = false;
//   String? _verificationCode;

//   final List<String> _purposes = [
//     'Interview',
//     'Meeting',
//     'Vendor',
//     'Delivery',
//     'Custom',
//   ];

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _mobileController.dispose();
//     _otpController.dispose();
//     super.dispose();
//   }

//   // --- Text Field Builder ---
//   Widget _buildTextField(
//     String label,
//     IconData icon,
//     TextInputType keyboardType,
//     TextEditingController controller, [
//     bool readOnly = false,
//   ]) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16.0),
//       child: TextFormField(
//         controller: controller,
//         readOnly: readOnly,
//         keyboardType: keyboardType,
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(icon, color: primaryGuardColor),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(10),
//             borderSide: const BorderSide(color: primaryGuardColor, width: 2),
//           ),
//         ),
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please enter the $label';
//           }
//           if (label.contains('Mobile') && value.length != 10) {
//             return 'Mobile number must be 10 digits';
//           }
//           if (label.contains('OTP') && value.length != 6) {
//             return 'OTP must be 6 digits';
//           }
//           return null;
//         },
//       ),
//     );
//   }

//   // --- Send OTP ---
//   void _sendOtp() {
//     if (!_formKey.currentState!.validate()) return;

//     if (_selectedPurpose == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select the purpose of visit.')),
//       );
//       return;
//     }

//     setState(() {
//       _otpSent = true;
//       _verificationCode = "123456"; // Dummy OTP
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           'OTP Sent to ${_mobileController.text}. (Code: $_verificationCode)',
//         ),
//       ),
//     );
//   }

//   // --- Verify OTP ---
//   void _verifyOtp() {
//     if (_otpController.text == _verificationCode) {
//       setState(() => _isVerified = true);

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Mobile number verified!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Invalid OTP! Please try again.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // --- Submit Visitor Request ---
//   void _submitForm() {
//     if (!_isVerified) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please verify the mobile number first.')),
//       );
//       return;
//     }

//     if (!_formKey.currentState!.validate() || _selectedPurpose == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please complete all required fields.')),
//       );
//       return;
//     }

//     final newRequestId = _dataService.addVisitorRequestAndGetId(
//       name: _nameController.text,
//       mobileNumber: _mobileController.text,
//       purpose: _selectedPurpose!,
//       context: context,
//     );

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Visitor Entry Request Sent! Awaiting owner response.'),
//         backgroundColor: primaryGuardColor,
//       ),
//     );

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) => GuardRequestStatusPage(
//           requestId: newRequestId,
//           primaryInfo: _nameController.text,
//           type: EntryType.visitor,
//         ),
//       ),
//     );
//   }

//   // --- Dropdown Builder ---
//   Widget _buildDropdownField(
//     String label,
//     IconData icon,
//     String? currentValue,
//     List<String> items,
//     Function(String?) onChanged,
//   ) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade400),
//         borderRadius: BorderRadius.circular(10),
//         color: Colors.white,
//       ),
//       child: DropdownButtonFormField<String>(
//         decoration: InputDecoration(
//           prefixIcon: Icon(icon, color: primaryGuardColor),
//           labelText: label,
//           border: InputBorder.none,
//         ),
//         value: currentValue,
//         items: items
//             .map((item) => DropdownMenuItem(value: item, child: Text(item)))
//             .toList(),
//         onChanged: onChanged,
//         validator: (value) => value == null ? '$label is required' : null,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: faintBackground,
//       appBar: AppBar(
//         title: const Text(
//           'Log New Visitor',
//           style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
//         ),
//         backgroundColor: Colors.white,
//         foregroundColor: Color(0xFF333333),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               _buildTextField(
//                 'Visitor Full Name',
//                 Icons.person_outline,
//                 TextInputType.name,
//                 _nameController,
//               ),

//               const SizedBox(height: 8),
//               _buildDropdownField(
//                 'Purpose of Visit',
//                 Icons.info_outline,
//                 _selectedPurpose,
//                 _purposes,
//                 (val) => setState(() => _selectedPurpose = val),
//               ),

//               const SizedBox(height: 16),
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: _buildTextField(
//                       'Mobile Number',
//                       Icons.phone_outlined,
//                       TextInputType.phone,
//                       _mobileController,
//                       _otpSent && !_isVerified,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   if (!_isVerified)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 4.0),
//                       child: ElevatedButton(
//                         onPressed: _otpSent ? null : _sendOtp,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: _otpSent
//                               ? Colors.grey
//                               : primaryGuardColor,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                         ),
//                         child: Text(_otpSent ? "OTP Sent" : "Send OTP"),
//                       ),
//                     ),
//                 ],
//               ),

//               if (_otpSent && !_isVerified)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 0),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: _buildTextField(
//                           'Enter 6-digit OTP',
//                           Icons.lock_outline,
//                           TextInputType.number,
//                           _otpController,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       ElevatedButton(
//                         onPressed: _verifyOtp,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                         ),
//                         child: const Text('Verify'),
//                       ),
//                     ],
//                   ),
//                 ),

//               if (_isVerified)
//                 const Padding(
//                   padding: EdgeInsets.only(top: 16),
//                   child: Row(
//                     children: [
//                       Icon(Icons.check_circle, color: Colors.green),
//                       SizedBox(width: 8),
//                       Text(
//                         'Mobile Verified Successfully!',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           color: Colors.green,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//               const SizedBox(height: 40),
//               ElevatedButton.icon(
//                 onPressed: _isVerified ? _submitForm : null,
//                 icon: const Icon(Icons.security),
//                 label: const Padding(
//                   padding: EdgeInsets.symmetric(vertical: 12.0),
//                   child: Text(
//                     'Request Entry Permission',
//                     style: TextStyle(fontSize: 18),
//                   ),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: _isVerified
//                       ? primaryGuardColor
//                       : Colors.grey,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
