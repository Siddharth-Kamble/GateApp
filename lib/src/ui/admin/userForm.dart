import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  late String _name;
  late String _email;
  late String _password;
  String _role = 'guard';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
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
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Map<String, dynamic> userData = {
        'name': _name,
        'email': _email,
        'password': _password, // For production, hash passwords!
        'role': _role,
        'isActive': _isActive,
        'createdAt': FieldValue.serverTimestamp(),
      };

      try {
        if (widget.docId != null) {
          // --- Edit existing user ---
          await widget.usersCollection.doc(widget.docId).update(userData);
          Navigator.pop(context, 'updated');
        } else {
          // --- Add new user ---
          await widget.usersCollection.add(userData);
          Navigator.pop(context, 'added');
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.docId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit User' : 'Add New User')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Name
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (val) => val!.isEmpty ? 'Enter name' : null,
                  onSaved: (val) => _name = val!,
                ),
                const SizedBox(height: 12),

                // Email / Username
                TextFormField(
                  initialValue: _email,
                  decoration: const InputDecoration(
                    labelText: 'Email / Username',
                  ),
                  validator: (val) =>
                      val!.isEmpty ? 'Enter email/username' : null,
                  onSaved: (val) => _email = val!,
                ),
                const SizedBox(height: 12),

                // Password
                TextFormField(
                  initialValue: _password,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (val) => val!.isEmpty ? 'Enter password' : null,
                  onSaved: (val) => _password = val!,
                ),
                const SizedBox(height: 12),

                // Role Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'owner', child: Text('Owner')),
                    DropdownMenuItem(value: 'guard', child: Text('Guard')),
                  ],
                  onChanged: (val) => setState(() => _role = val!),
                ),
                const SizedBox(height: 12),

                // Active Switch
                SwitchListTile(
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  title: const Text('Active'),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: Text(isEditing ? 'Update User' : 'Add User'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
