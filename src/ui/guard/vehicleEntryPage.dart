// // import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart'; // Import image_picker
// // import 'dart:io'; // Required for File

// // // --- Constants (Matching the theme) ---
// // const Color primaryGuardColor = Color(0xFF00ACC1);
// // const Color faintBackground = Color(0xFFF9F9FB);
// // const Color vehicleAccentColor = Color(0xFFFFB300); // Amber

// // class VehicleEntryPage extends StatefulWidget {
// //   const VehicleEntryPage({super.key});

// //   @override
// //   State<VehicleEntryPage> createState() => _VehicleEntryPageState();
// // }

// // class _VehicleEntryPageState extends State<VehicleEntryPage> {
// //   final _formKey = GlobalKey<FormState>();
// //   String? _selectedVehicleType;

// //   // Controllers for form fields
// //   final TextEditingController _licensePlateController = TextEditingController();
// //   final TextEditingController _driverNameController = TextEditingController();

// //   File? _vehicleImage; // Variable to store the selected image file
// //   final ImagePicker _picker = ImagePicker(); // Image picker instance

// //   final List<String> _vehicleTypes = [
// //     'Car',
// //     'Truck/Lorry',
// //     'Delivery Van',
// //     'Other',
// //   ];

// //   @override
// //   void dispose() {
// //     _licensePlateController.dispose();
// //     _driverNameController.dispose();
// //     super.dispose();
// //   }

// //   // --- Form Field Builder ---
// //   Widget _buildTextField(
// //     String label,
// //     IconData icon,
// //     TextInputType keyboardType,
// //     TextEditingController controller,
// //   ) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 16.0),
// //       child: TextFormField(
// //         controller: controller,
// //         keyboardType: keyboardType,
// //         decoration: InputDecoration(
// //           labelText: label,
// //           prefixIcon: Icon(icon, color: vehicleAccentColor),
// //           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
// //           focusedBorder: OutlineInputBorder(
// //             borderRadius: BorderRadius.circular(10),
// //             borderSide: const BorderSide(color: vehicleAccentColor, width: 2),
// //           ),
// //         ),
// //         validator: (value) {
// //           if (value == null || value.isEmpty) {
// //             return 'Please enter the $label';
// //           }
// //           return null;
// //         },
// //       ),
// //     );
// //   }

// //   // --- Image Picker Method ---
// //   Future<void> _pickImage() async {
// //     final XFile? pickedFile = await _picker.pickImage(
// //       source: ImageSource.gallery,
// //       imageQuality: 80,
// //     );
// //     if (pickedFile != null) {
// //       setState(() {
// //         _vehicleImage = File(pickedFile.path);
// //       });
// //     } else {
// //       // User canceled the picker
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(const SnackBar(content: Text('No image selected.')));
// //     }
// //   }

// //   // --- Submission Handler ---
// //   void _submitForm() {
// //     if (_formKey.currentState!.validate()) {
// //       if (_selectedVehicleType == null) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('Please select the vehicle type.')),
// //         );
// //         return;
// //       }
// //       if (_vehicleImage == null) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('Please add a vehicle image.')),
// //         );
// //         return;
// //       }

// //       // Successful Submission Logic (Simulated)
// //       // In a real app, you would upload _vehicleImage to a server
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text(
// //             'Vehicle Logged. Type: $_selectedVehicleType, Image: ${_vehicleImage!.path.split('/').last}',
// //           ),
// //           backgroundColor: Colors.blueGrey,
// //         ),
// //       );
// //       // Navigate back to the Guard home page
// //       Navigator.pop(context);
// //     }
// //   }

// //   // --- Generic Dropdown Field Builder ---
// //   Widget _buildDropdownField(
// //     String label,
// //     IconData icon,
// //     String? currentValue,
// //     List<String> items,
// //     Function(String?) onChanged,
// //   ) {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 12),
// //       margin: const EdgeInsets.only(bottom: 16.0), // Added margin for spacing
// //       decoration: BoxDecoration(
// //         border: Border.all(color: Colors.grey.shade400),
// //         borderRadius: BorderRadius.circular(10),
// //         color: Colors.white,
// //       ),
// //       child: DropdownButtonFormField<String>(
// //         decoration: InputDecoration(
// //           prefixIcon: Icon(icon, color: vehicleAccentColor),
// //           labelText: label,
// //           border: InputBorder.none,
// //         ),
// //         value: currentValue,
// //         hint: Text('Select $label'),
// //         items: items.map((String item) {
// //           return DropdownMenuItem<String>(value: item, child: Text(item));
// //         }).toList(),
// //         onChanged: onChanged,
// //         validator: (value) {
// //           if (value == null || value.isEmpty) {
// //             return '$label is required';
// //           }
// //           return null;
// //         },
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: faintBackground,
// //       appBar: AppBar(
// //         title: const Text(
// //           'Log New Vehicle',
// //           style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
// //         ),
// //         backgroundColor: Colors.white,
// //         foregroundColor: const Color(0xFF333333),
// //         elevation: 1,
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(24.0),
// //         child: Form(
// //           key: _formKey,
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.stretch,
// //             children: [
// //               // 1. License Plate
// //               _buildTextField(
// //                 'License Plate/Reg. No.',
// //                 Icons.credit_card_outlined,
// //                 TextInputType.text,
// //                 _licensePlateController,
// //               ),

// //               // 2. Driver Name
// //               _buildTextField(
// //                 'Driver Name',
// //                 Icons.person_outline,
// //                 TextInputType.name,
// //                 _driverNameController,
// //               ),

// //               // 3. Vehicle Type Dropdown
// //               _buildDropdownField(
// //                 'Vehicle Type',
// //                 Icons.directions_car_filled_outlined,
// //                 _selectedVehicleType,
// //                 _vehicleTypes,
// //                 (newValue) => setState(() => _selectedVehicleType = newValue),
// //               ),

// //               const SizedBox(height: 16),

// //               // 4. Image Input Button
// //               ElevatedButton.icon(
// //                 onPressed: _pickImage,
// //                 icon: const Icon(Icons.add_a_photo_outlined),
// //                 label: const Padding(
// //                   padding: EdgeInsets.symmetric(vertical: 12.0),
// //                   child: Text(
// //                     'Add Vehicle Image',
// //                     style: TextStyle(fontSize: 18),
// //                   ),
// //                 ),
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: vehicleAccentColor.withOpacity(
// //                     0.8,
// //                   ), // Slightly subdued
// //                   foregroundColor: Colors.white,
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(10),
// //                   ),
// //                   elevation: 3,
// //                 ),
// //               ),
// //               const SizedBox(height: 16),

// //               // 5. Image Preview
// //               if (_vehicleImage != null)
// //                 Container(
// //                   height: 200,
// //                   width: double.infinity,
// //                   decoration: BoxDecoration(
// //                     border: Border.all(color: Colors.grey.shade300),
// //                     borderRadius: BorderRadius.circular(10),
// //                   ),
// //                   child: ClipRRect(
// //                     borderRadius: BorderRadius.circular(10),
// //                     child: Image.file(_vehicleImage!, fit: BoxFit.cover),
// //                   ),
// //                 )
// //               else
// //                 Container(
// //                   height: 150,
// //                   width: double.infinity,
// //                   decoration: BoxDecoration(
// //                     color: Colors.grey[200],
// //                     borderRadius: BorderRadius.circular(10),
// //                     border: Border.all(color: Colors.grey.shade300),
// //                   ),
// //                   child: Column(
// //                     mainAxisAlignment: MainAxisAlignment.center,
// //                     children: [
// //                       Icon(
// //                         Icons.image_not_supported_outlined,
// //                         size: 50,
// //                         color: Colors.grey[600],
// //                       ),
// //                       const SizedBox(height: 8),
// //                       Text(
// //                         'No image selected',
// //                         style: TextStyle(color: Colors.grey[600]),
// //                       ),
// //                     ],
// //                   ),
// //                 ),

// //               const SizedBox(height: 40),

// //               // 6. Submit Button
// //               ElevatedButton.icon(
// //                 onPressed: _submitForm,
// //                 icon: const Icon(Icons.check_circle_outline),
// //                 label: const Padding(
// //                   padding: EdgeInsets.symmetric(vertical: 12.0),
// //                   child: Text(
// //                     'Check In Vehicle',
// //                     style: TextStyle(fontSize: 18),
// //                   ),
// //                 ),
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: vehicleAccentColor,
// //                   foregroundColor: Colors.white,
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(10),
// //                   ),
// //                   elevation: 5,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';

// import 'package:flutter_application_1/src/services/DataService.dart'
//     show DataService; // Import the new data service

// const Color primaryGuardColor = Color(0xFF00ACC1); // Teal
// const Color faintBackground = Color(0xFFF9F9FB);
// const double cardRadius = 16.0;

// class VehicleEntryPage extends StatefulWidget {
//   const VehicleEntryPage({super.key});

//   @override
//   State<VehicleEntryPage> createState() => _GuardVehicleEntryPageState();
// }

// class _GuardVehicleEntryPageState extends State<VehicleEntryPage> {
//   final _formKey = GlobalKey<FormState>();
//   final DataService _dataService = DataService();

//   String _vehicleNumber = '';
//   String _driverName = '';
//   String _unitNumber = '';
//   String _purpose = '';

//   void _submitRequest() {
//     if (_formKey.currentState!.validate()) {
//       _formKey.currentState!.save();

//       // --- 💡 Core Implementation: Send Pending Request ---
//       _dataService.addRequest(
//         vehicleNumber: _vehicleNumber,
//         driverName: _driverName,
//         unitNumber: _unitNumber,
//         purpose: _purpose,
//       );

//       // Show success message and navigate back
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Vehicle Entry Request Sent! Owner is notified.'),
//           backgroundColor: primaryGuardColor,
//         ),
//       );

//       Navigator.pop(context); // Go back to the guard's home page
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: faintBackground,
//       appBar: AppBar(
//         title: const Text(
//           'New Vehicle Request',
//           style: TextStyle(fontWeight: FontWeight.w700),
//         ),
//         backgroundColor: Colors.white,
//         foregroundColor: primaryGuardColor,
//         elevation: 1,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               _buildInputField(
//                 label: 'Vehicle Number (Plate)',
//                 icon: Icons.directions_car,
//                 onSaved: (value) => _vehicleNumber = value!,
//               ),
//               const SizedBox(height: 20),
//               _buildInputField(
//                 label: 'Driver Name',
//                 icon: Icons.person_outline,
//                 onSaved: (value) => _driverName = value!,
//               ),
//               const SizedBox(height: 20),
//               _buildInputField(
//                 label: 'Target Unit Number',
//                 icon: Icons.home_work_outlined,
//                 onSaved: (value) => _unitNumber = value!,
//               ),
//               const SizedBox(height: 20),
//               _buildInputField(
//                 label: 'Purpose of Visit',
//                 icon: Icons.info_outline,
//                 onSaved: (value) => _purpose = value!,
//               ),
//               const SizedBox(height: 40),
//               ElevatedButton.icon(
//                 onPressed: _submitRequest,
//                 icon: const Icon(Icons.send),
//                 label: const Text('Send Owner Approval Request'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: primaryGuardColor,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 15),
//                   textStyle: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(cardRadius),
//                   ),
//                   elevation: 5,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInputField({
//     required String label,
//     required IconData icon,
//     required FormFieldSetter<String> onSaved,
//   }) {
//     return TextFormField(
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon, color: primaryGuardColor.withOpacity(0.7)),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(cardRadius / 2),
//           borderSide: BorderSide.none,
//         ),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: const EdgeInsets.symmetric(
//           vertical: 18,
//           horizontal: 15,
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(cardRadius / 2),
//           borderSide: const BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(cardRadius / 2),
//           borderSide: const BorderSide(color: primaryGuardColor, width: 2),
//         ),
//       ),
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return 'Please enter the $label';
//         }
//         return null;
//       },
//       onSaved: onSaved,
//     );
//   }
// }
