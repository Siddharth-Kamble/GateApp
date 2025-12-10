import 'package:cloud_firestore/cloud_firestore.dart'
    show CollectionReference, DocumentSnapshot, FieldValue;
import 'package:flutter/material.dart'
    show
        State,
        StatefulWidget,
        FormState,
        TextEditingController,
        SnackBar,
        BuildContext,
        Widget,
        EdgeInsets,
        InputDecoration,
        SizedBox,
        Center,
        GlobalKey,
        ScaffoldMessenger,
        Text,
        Navigator,
        AppBar,
        TextFormField,
        DropdownMenuItem,
        DropdownButtonFormField,
        SwitchListTile,
        CircularProgressIndicator,
        ElevatedButton,
        ListView,
        Form,
        Padding,
        Scaffold;
import 'package:flutter_application_1/src/ui/admin/dashboard.dart'
    show primaryBlue;

class ManageUsersPage extends StatefulWidget {
  final CollectionReference usersCollection;
  final DocumentSnapshot? userDoc; // null if adding new user

  const ManageUsersPage({
    super.key,
    required this.usersCollection,
    this.userDoc,
  });

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _passwordController;

  String _role = 'user';
  bool _isActive = true;
  bool _isLoading = false;

  bool get isEditing => widget.userDoc != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: isEditing ? widget.userDoc!['name'] : '',
    );
    _emailController = TextEditingController(
      text: isEditing ? widget.userDoc!['email'] : '',
    );
    _mobileController = TextEditingController(
      text: isEditing ? widget.userDoc!['mobile'] : '',
    );
    _passwordController = TextEditingController(
      text: isEditing ? widget.userDoc!['password'] : '',
    );

    if (isEditing) {
      _role = widget.userDoc!['role'] ?? 'user';
      _isActive = widget.userDoc!['isActive'] ?? true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Map<String, dynamic> userData = {
      'name': _nameController.text,
      'email': _emailController.text,
      'mobile': _mobileController.text,
      'password': _passwordController.text,
      'role': _role,
      'isActive': _isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (isEditing) {
        // Update existing user
        await widget.usersCollection.doc(widget.userDoc!.id).update(userData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully!')),
        );
      } else {
        // Add new user
        userData['createdAt'] = FieldValue.serverTimestamp();
        await widget.usersCollection.add(userData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully!')),
        );
      }

      if (mounted) Navigator.pop(context, 'saved');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit User' : 'Add User'),
        backgroundColor: primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val!.isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (val) => val!.isEmpty ? 'Please enter email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: 'Mobile'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'guard', child: Text('Guard')),
                  DropdownMenuItem(value: 'user', child: Text('User')),
                ],
                onChanged: (val) => setState(() => _role = val!),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
                title: Text(_isActive ? 'Status: Active' : 'Status: Inactive'),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveUser,
                      child: Text(isEditing ? 'Update User' : 'Add User'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
