import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/src/models/user_model.dart';
import 'package:flutter_application_1/src/ui/guard/GuardDashboard.dart'
    show GuardDashboard;
// Adjust path

class GuardLoginPage extends StatefulWidget {
  const GuardLoginPage({super.key});

  @override
  State<GuardLoginPage> createState() => _GuardLoginPageState();
}

class _GuardLoginPageState extends State<GuardLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final inputEmail = _emailController.text.trim();
    final inputPassword = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      final QuerySnapshot snap = await usersCollection
          .where('email', isEqualTo: inputEmail)
          .where('role', isEqualTo: 'guard')
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email not found or not a guard')),
        );
        return;
      }

      final doc = snap.docs.first;
      final Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

      // Check password
      if ((userData['password'] ?? '') != inputPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect password')),
        );
        return;
      }

      // Check active status
      if ((userData['isActive'] ?? true) == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is inactive')),
        );
        return;
      }

      // Build UserModel
      final UserModel loggedInUser = UserModel.fromMap(userData, doc.id);

      // Navigate to GuardDashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GuardDashboard(loggedInUser: loggedInUser),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guard Portal'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield, size: 60, color: primaryColor),
                    const SizedBox(height: 8),
                    Text(
                      'Guard Login',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          val!.isEmpty ? 'Please enter email' : null,
                    ),

                    const SizedBox(height: 20),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
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
                      obscureText: !_isPasswordVisible,
                      validator: (val) =>
                          val!.isEmpty ? 'Please enter password' : null,
                    ),

                    const SizedBox(height: 40),

                    _isLoading
                        ? CircularProgressIndicator(color: primaryColor)
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              onPressed: _login,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor: primaryColor,
                                elevation: 5,
                              ),
                              child: const Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
