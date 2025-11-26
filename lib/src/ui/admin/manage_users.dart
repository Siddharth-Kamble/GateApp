import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color primaryBlue = Color(0xFF42A5F5);
const double cardRadius = 12.0;

class ManageUsersPage extends StatefulWidget {
  final CollectionReference usersCollection;

  const ManageUsersPage({super.key, required this.usersCollection});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _selectedCountryCode = '+91';
  String? _verificationId;
  bool _otpSent = false;
  bool _isLoading = false;

  // Step 1: Send OTP
  Future<void> _sendOtp() async {
    if (_mobileController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter mobile number')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '$_selectedCountryCode${_mobileController.text}',
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto verification
          await FirebaseAuth.instance.signInWithCredential(credential);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone automatically verified!')),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.code} - ${e.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
          setState(() => _isLoading = false);
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent! Check your SMS.')),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e, stackTrace) {
      print('Send OTP error: $e');
      print(stackTrace);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending OTP: $e')));
      setState(() => _isLoading = false);
    }
  }

  // Step 2: Verify OTP
  Future<bool> _verifyOtp() async {
    if (_otpController.text.isEmpty ||
        _otpController.text.length != 6 ||
        _verificationId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter 6-digit OTP')));
      return false;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await FirebaseAuth.instance.signOut(); // Only verifying OTP
      return true;
    } catch (e, stackTrace) {
      print('OTP verification error: $e');
      print(stackTrace);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
      return false;
    }
  }

  // Step 3: Add user to Firestore
  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    bool verified = await _verifyOtp();
    if (!verified) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await widget.usersCollection.add({
        'name': _nameController.text,
        'username': _usernameController.text,
        'mobile': '$_selectedCountryCode${_mobileController.text}',
        'password': _passwordController.text,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User added successfully!')));

      _nameController.clear();
      _usernameController.clear();
      _mobileController.clear();
      _passwordController.clear();
      _otpController.clear();
      setState(() {
        _otpSent = false;
        _verificationId = null;
      });
    } catch (e, stackTrace) {
      print('Add user error: $e');
      print(stackTrace);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding user: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: primaryBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter username' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter password' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedCountryCode,
                    items: const [
                      DropdownMenuItem(
                        value: '+91',
                        child: Text('+91 (India)'),
                      ),
                      DropdownMenuItem(value: '+1', child: Text('+1 (USA)')),
                      DropdownMenuItem(value: '+44', child: Text('+44 (UK)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCountryCode = val);
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter mobile number'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_otpSent)
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP (6 digits)',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _otpSent ? _addUser : _sendOtp,
                            child: Text(
                              _otpSent ? 'Verify & Add User' : 'Send OTP',
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
