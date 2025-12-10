import 'package:flutter/material.dart';
// NOTE: Ensure this path is correct for your project structure
import '../admin/dashboard.dart';

// Custom colors for Admin panel
const Color adminPrimaryColor = Color(0xFF3949AB); // Indigo
const Color adminBackgroundColor = Color(0xFFF4F4FB);
const Color adminCardColor = Colors.white;

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
  bool _isPasswordVisible = false;

  // Default admin credentials (DEMO ONLY)
  final String defaultUsername = 'admin';
  final String defaultPassword = 'admin123';

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (_username == defaultUsername && _password == defaultPassword) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else {
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

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = adminPrimaryColor;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF283593), // darker indigo
              adminBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top brand/header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Admin Control Panel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Card
                    Card(
                      color: adminCardColor,
                      elevation: 12,
                      shadowColor: Colors.black.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(28, 32, 28, 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title & subtitle
                              const Text(
                                'Admin Login',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF25233A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Sign in to manage users, gates and reports.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF81809A),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Username
                              TextFormField(
                                decoration: _inputDecoration(
                                  labelText: 'Username',
                                  hintText: 'Enter your admin username',
                                  icon: Icons.person_outline,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Please enter a username'
                                    : null,
                                onSaved: (val) => _username = val!.trim(),
                              ),
                              const SizedBox(height: 18),

                              // Password
                              TextFormField(
                                decoration: _inputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter your password',
                                  icon: Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: primaryColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: !_isPasswordVisible,
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Please enter a password'
                                    : null,
                                onSaved: (val) => _password = val!.trim(),
                              ),
                              const SizedBox(height: 10),

                              
                              const SizedBox(height: 26),

                              // Login button or loader
                              _isLoading
                                  ? const SizedBox(
                                      height: 46,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation(
                                            primaryColor,
                                          ),
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          elevation: 6,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          'LOGIN',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                    ),

                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 14,
                                    color: Color(0xFFB1B7C7),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Restricted access • Admins only',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFB1B7C7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  // Unified input decoration
  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(
        icon,
        color: adminPrimaryColor.withOpacity(0.9),
      ),
      filled: true,
      fillColor: adminBackgroundColor,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: adminPrimaryColor, width: 2),
      ),
      floatingLabelStyle: const TextStyle(color: adminPrimaryColor),
    );
  }
}
