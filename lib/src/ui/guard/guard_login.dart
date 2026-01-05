import 'package:cloud_firestore/cloud_firestore.dart'
    show QuerySnapshot, FirebaseFirestore, CollectionReference;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/ui/shared/role_selection.dart' show RoleSelectionPage;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/src/models/user_model.dart';
import 'package:flutter_application_1/src/ui/guard/GuardDashboard.dart'
    show GuardDashboard;

// --- Custom Guard Colors ---
const Color guardPrimaryColor = Color(0xFF1565C0); // Security blue
const Color guardBackground = Color(0xFFF4F6FB);
const Color guardCardColor = Colors.white;

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

  @override
  void initState() {
    super.initState();
    _checkAlreadyLoggedIn();
  }

  /// Agar guard pehle se logged in hai (guardUserId stored hai)
  /// to direct GuardDashboard pe bhej do.
  Future<void> _checkAlreadyLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedUserId = prefs.getString('guardUserId');

      if (savedUserId == null) return; // koi saved guard nahi, login screen dikhao

      final doc = await usersCollection.doc(savedUserId).get();

      if (!doc.exists) {
        // User delete ho gaya ho sakta hai
        await prefs.remove('guardUserId');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      // Agar beech me inactive kar diya gaya ho
      if ((data['isActive'] ?? true) == false) {
        await prefs.remove('guardUserId');
        return;
      }

      final UserModel loggedInUser = UserModel.fromMap(data, doc.id);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GuardDashboard(loggedInUser: loggedInUser),
        ),
      );
    } catch (e) {
      debugPrint('Auto login error: $e');
      // Error ho to normal login screen hi dikhegi
    }
  }

  // -------------------- LOGIN LOGIC --------------------
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
      final Map<String, dynamic> userData =
          doc.data() as Map<String, dynamic>;

      if ((userData['password'] ?? '') != inputPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect password')),
        );
        return;
      }

      if ((userData['isActive'] ?? true) == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is inactive')),
        );
        return;
      }

      final UserModel loggedInUser = UserModel.fromMap(userData, doc.id);

      // 🔹 Guard ko local storage me save karo taaki next time direct login ho
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guardUserId', doc.id);

      if (!mounted) return;
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ----------------------------- UI -----------------------------
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = guardPrimaryColor;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1), // darker blue top
              guardBackground,
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
                  Align(
  alignment: Alignment.centerLeft,
  child: TextButton.icon(
    onPressed: () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
        (route) => false,
      );
    },
    icon: const Icon(Icons.arrow_back, color: Colors.white),
    label: const Text(
      'Back to Role Selection',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
),
const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.shield_outlined,
                            color: Colors.white, size: 26),
                        SizedBox(width: 8),
                        Text(
                          "Security Gate – Guard Panel",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ------------------- CARD -------------------
                    Card(
                      color: guardCardColor,
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.2),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  image: const DecorationImage(
                                    image: AssetImage(
                                        'lib/src/assets/guardlogo.jpg'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              const Text(
                                'Guard Login',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2430),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Authenticate to manage visitor entries.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF7A7F8C),
                                ),
                              ),
                              const SizedBox(height: 26),

                              // Username
                              TextFormField(
                                controller: _emailController,
                                decoration: _inputDecoration(
                                  labelText: 'Username',
                                  hintText: 'Enter your username',
                                  icon: Icons.person_outline,
                                ),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Please enter username'
                                    : null,
                              ),
                              const SizedBox(height: 18),

                              // Password
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: _inputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter password',
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
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Please enter password'
                                    : null,
                              ),
                              const SizedBox(height: 8),

                              const Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Only authorized guards can login',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9AA1AF),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 26),

                              // Login button
                              _isLoading
                                  ? const SizedBox(
                                      height: 46,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  primaryColor),
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: FilledButton(
                                        onPressed: _login,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 6,
                                        ),
                                        child: const Text(
                                          'LOGIN',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),

                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.verified_user_outlined,
                                      size: 14, color: Color(0xFFB0B7C3)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Secure access – Gate staff only',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFB0B7C3),
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

  // Unified decoration for fields
  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon, color: guardPrimaryColor.withOpacity(0.8)),
      filled: true,
      fillColor: guardBackground,
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
        borderSide: BorderSide(color: guardPrimaryColor, width: 2),
      ),
      floatingLabelStyle: const TextStyle(color: guardPrimaryColor),
    );
  }
}
