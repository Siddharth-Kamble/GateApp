import 'package:flutter/material.dart';

// --- Constants (Matching the theme) ---
const Color primaryBlue = Color(0xFF42A5F5);
const Color faintBackground = Color(0xFFF9F9FB);

class AddNewUserPage extends StatefulWidget {
  const AddNewUserPage({super.key});

  @override
  State<AddNewUserPage> createState() => _AddNewUserPageState();
}

class _AddNewUserPageState extends State<AddNewUserPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedRole;

  // Dummy list of available roles
  final List<String> _roles = [
    'System Admin',
    'Security Guard',
    'Staff',
    'Owner',
  ];

  // --- Form Field Builder ---
  Widget _buildTextField(
    String label,
    IconData icon,
    TextInputType keyboardType,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryBlue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the $label';
          }
          return null;
        },
      ),
    );
  }

  // --- Submission Handler ---
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a role for the user.')),
        );
        return;
      }

      // 💡 Successful Submission Logic (Displaying Success message)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User details submitted successfully with Role: $_selectedRole',
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate back to the Manage Users page
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: faintBackground,
      appBar: AppBar(
        title: const Text(
          'Add New User',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Name
              _buildTextField(
                'Full Name',
                Icons.person_outline,
                TextInputType.name,
              ),

              // 2. Email
              _buildTextField(
                'Email Address',
                Icons.email_outlined,
                TextInputType.emailAddress,
              ),

              // 3. Mobile No
              _buildTextField(
                'Mobile Number',
                Icons.phone_outlined,
                TextInputType.phone,
              ),

              const SizedBox(height: 8),

              // 4. Role Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.shield_outlined, color: primaryBlue),
                    labelText: 'User Role',
                    border: InputBorder.none,
                  ),
                  value: _selectedRole,
                  hint: const Text('Select a Role'),
                  items: _roles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRole = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Role is required';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 40),

              // 5. Submit Button
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.save),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Add User', style: TextStyle(fontSize: 18)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
