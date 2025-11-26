import 'package:flutter/material.dart';
// NOTE: Ensure this path is correct for your project structure
import '../admin/dashboard.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  bool _isLoading = false;
  // State variable to toggle password visibility
  bool _isPasswordVisible = false;

  // Default admin credentials (FOR DEMO ONLY - DO NOT USE IN PRODUCTION)
  final String defaultUsername = 'admin';
  final String defaultPassword = 'admin123';

  void _login() async {
    // 1. Validate the form inputs
    if (!_formKey.currentState!.validate()) return;

    // 2. Save the inputs to the state variables
    _formKey.currentState!.save();

    // 3. Start loading and update UI
    setState(() => _isLoading = true);

    // 4. Simulate network delay for a better user experience
    await Future.delayed(const Duration(milliseconds: 1500));

    // 5. Check credentials
    if (_username == defaultUsername && _password == defaultPassword) {
      // Login success: navigate to dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      }
    } else {
      // Login failed: show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid username or password',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    // 6. Stop loading
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the primary color from the theme for consistent branding
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Portal'),
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
                    // --- Logo/Branding Section ---
                    Icon(Icons.security, size: 60, color: primaryColor),
                    const SizedBox(height: 8),
                    Text(
                      'Admin Login',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- Username Field ---
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter your admin username',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) =>
                          val!.isEmpty ? 'Please enter a username' : null,
                      onSaved: (val) => _username = val!,
                    ),

                    const SizedBox(height: 20),

                    // --- Password Field ---
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        // Visibility Toggle Implementation
                        suffixIcon: IconButton(
                          icon: Icon(
                            // Change icon based on visibility state
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: primaryColor,
                          ),
                          onPressed: () {
                            // Toggle the state of password visibility
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      // Set obscurity based on the state
                      obscureText: !_isPasswordVisible,
                      validator: (val) =>
                          val!.isEmpty ? 'Please enter a password' : null,
                      onSaved: (val) => _password = val!,
                    ),

                    const SizedBox(height: 40),

                    // --- Login Button / Loading Indicator ---
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

// NOTE: You will also need a basic AdminDashboard widget for this code to run successfully.
// Example placeholder:
/*
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: const Center(
        child: Text('Welcome, Admin!', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
*/
