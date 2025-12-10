import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Theme Constants ---
const Color primaryColor = Color(0xFF42A5F5); // A pleasant blue
const double cardRadius = 16.0;
const EdgeInsets fieldPadding = EdgeInsets.only(bottom: 20);

// --- Add/Edit User Page ---
class AddNewUserPage extends StatefulWidget {
  final CollectionReference usersCollection;
  final String? docId; // null for add, not null for edit
  final Map<String, dynamic>? existingData;

  const AddNewUserPage({
    super.key,
    required this.usersCollection,
    this.docId,
    this.existingData,
  });

  @override
  State<AddNewUserPage> createState() => _AddNewUserPageState();
}

class _AddNewUserPageState extends State<AddNewUserPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to manage initial values and state after validation/submission
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  late String _name;
  late String _email;
  late String _password;
  late String _role;
  late bool _isActive;
  bool _isPasswordVisible = false; // New state for password toggle
  bool _isSubmitting = false;

  bool get isEditing => widget.docId != null;

  @override
  void initState() {
    super.initState();

    // Initialize state variables from existing data or default values
    if (widget.existingData != null) {
      _name = widget.existingData!['name'] ?? '';
      _email = widget.existingData!['email'] ?? '';
      _password = widget.existingData!['password'] ?? '';
      _role = widget.existingData!['role'] ?? 'guard';
      _isActive = widget.existingData!['isActive'] ?? true;
    } else {
      _name = '';
      _email = '';
      _password = '';
      _role = 'guard';
      _isActive = true;
    }

    // Initialize controllers with the determined values
    _nameController = TextEditingController(text: _name);
    _emailController = TextEditingController(text: _email);
    _passwordController = TextEditingController(text: _password);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    Map<String, dynamic> userData = {
      'name': _name,
      'email': _email,
      'password': _password, // WARNING: Hash passwords in production!
      'role': _role,
      'isActive': _isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Only set createdAt for new records
    if (!isEditing) {
      userData['createdAt'] = FieldValue.serverTimestamp();
    }

    try {
      if (widget.docId != null) {
        // --- Edit existing user ---
        await widget.usersCollection.doc(widget.docId).update(userData);
        if (mounted) Navigator.pop(context, 'updated');
      } else {
        // --- Add new user ---
        await widget.usersCollection.add(userData);
        if (mounted) Navigator.pop(context, 'added');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User ${isEditing ? 'updated' : 'added'} successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- Reusable Themed TextFormField Widget ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Function(String?) onSaved,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: fieldPadding,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryColor, width: 2.0),
          ),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: (val) => val!.isEmpty ? 'Please enter $label' : null,
        onSaved: onSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit User' : 'Add New User',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cardRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Name Field ---
                    _buildTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      onSaved: (val) => _name = val!,
                      icon: Icons.person_outline,
                    ),

                    // --- Email / Username Field ---
                    _buildTextField(
                      label: 'Email / Username',
                      controller: _emailController,
                      onSaved: (val) => _email = val!,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    // --- Password Field with Toggle ---
                    _buildTextField(
                      label: 'Password',
                      controller: _passwordController,
                      onSaved: (val) => _password = val!,
                      icon: Icons.lock_outline,
                      obscureText: !_isPasswordVisible, // Controlled by state
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),

                    // --- Role Dropdown ---
                    Padding(
                      padding: fieldPadding,
                      child: DropdownButtonFormField<String>(
                        initialValue: _role,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          prefixIcon: const Icon(
                            Icons.security,
                            color: primaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'owner',
                            child: Text('Owner'),
                          ),
                          DropdownMenuItem(
                            value: 'guard',
                            child: Text('Guard'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ), // Added Admin role option
                        ],
                        onChanged: (val) => setState(() => _role = val!),
                        onSaved: (val) => _role = val!,
                      ),
                    ),

                    // --- Active Switch ---
                    SwitchListTile(
                      value: _isActive,
                      onChanged: (val) => setState(() => _isActive = val),
                      title: Text(
                        _isActive ? 'Status: Active' : 'Status: Inactive',
                        style: TextStyle(
                          color: _isActive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      secondary: Icon(
                        _isActive
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        color: _isActive ? Colors.green : Colors.red,
                      ),
                      activeThumbColor: primaryColor,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 30),

                    // --- Submit Button ---
                    _isSubmitting
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          )
                        : SizedBox(
                            height: 50,
                            child: FilledButton.icon(
                              onPressed: _submitForm,
                              icon: Icon(
                                isEditing ? Icons.save : Icons.person_add,
                              ),
                              label: Text(
                                isEditing ? 'UPDATE USER' : 'ADD NEW USER',
                                style: const TextStyle(fontSize: 18),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
