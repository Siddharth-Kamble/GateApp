import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/src/models/user_model.dart';
import 'package:flutter_application_1/src/ui/owner/owner_dashboard.dart'
    show OwnerDashboard;
import 'package:flutter_application_1/src/services/fcm_service.dart';
import 'package:flutter_application_1/src/ui/shared/role_selection.dart'
    show RoleSelectionPage;
import 'package:shared_preferences/shared_preferences.dart';

// --- Custom Colors ---
const Color primaryOwnerColor = Color(0xFF673AB7); // Deep Purple
const Color accentYellow = Color(0xFFFFC107);
const Color faintBackground = Color(0xFFF5F4FA);
const Color cardColor = Colors.white;

class OwnerLoginPage extends StatefulWidget {
  const OwnerLoginPage({super.key});

  @override
  State<OwnerLoginPage> createState() => _OwnerLoginPageState();
}

class _OwnerLoginPageState extends State<OwnerLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _checkingExistingLogin = true; // ✅ NEW: to show loader while checking

  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  @override
  void initState() {
    super.initState();
    _checkExistingLogin(); // ✅ NEW: auto-login check
  }

  // ✅ NEW: Check if owner already logged in earlier
  Future<void> _checkExistingLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedOwnerId = prefs.getString('owner_uid');

      if (savedOwnerId != null) {
        // Fetch owner from Firestore and auto-login
        final doc = await usersCollection.doc(savedOwnerId).get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['role'] == 'owner') {
            final loggedInOwner = UserModel.fromMap(data, doc.id);

            if (!mounted) return;

            // Direct jump to dashboard
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => OwnerDashboard(loggedInOwner: loggedInOwner),
              ),
              (route) => false,
            );
            return;
          }
        }
      }
    } catch (e) {
      // Ignore errors here, just show login screen normally
    } finally {
      if (mounted) {
        setState(() {
          _checkingExistingLogin = false;
        });
      }
    }
  }

  // --- LOGIN FUNCTIONALITY ---
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final snap = await usersCollection
          .where('email', isEqualTo: _emailController.text.trim())
          .where('role', isEqualTo: 'owner')
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Owner not found or invalid username'),
            ),
          );
        }
        return;
      }

      final doc = snap.docs.first;
      final userData = doc.data() as Map<String, dynamic>;

      if ((userData['password'] ?? '') != _passwordController.text.trim()) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Incorrect password')));
        }
        return;
      }

      final loggedInOwner = UserModel.fromMap(userData, doc.id);

      // --- SAVE OWNER FCM TOKEN ---
      await FCMService().saveOwnerFCMToken(loggedInOwner.uid!);

      // ✅ SAVE LOGIN LOCALLY FOR AUTO-LOGIN
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('owner_uid', loggedInOwner.uid!);

      if (!mounted) return;

      // Clear fields after successful login (optional)
      _emailController.clear();
      _passwordController.clear();

      // DIRECT LOGIN TO DASHBOARD, CLEARING PREVIOUS ROUTES
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OwnerDashboard(loggedInOwner: loggedInOwner),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    const Color buttonColor = primaryOwnerColor;

    // ✅ While checking existing login, show loader
    if (_checkingExistingLogin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: primaryOwnerColor),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6D3BD8), faintBackground],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
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
                            MaterialPageRoute(
                              builder: (_) => const RoleSelectionPage(),
                            ),
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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.apartment_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "MyGate Owner",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Card ---
                    Container(
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Owner Login',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B2440),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Sign in to review visitor and employee passes.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF77758A),
                              ),
                            ),
                            const SizedBox(height: 30),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDecoration(
                                labelText: "Username",
                                icon: Icons.person_outline,
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? "Username required"
                                  : null,
                            ),
                            const SizedBox(height: 18),

                            TextFormField(
                              controller: _passwordController,
                              decoration:
                                  _inputDecoration(
                                    labelText: "Password",
                                    icon: Icons.lock_outline,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.grey.shade500,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                              obscureText: _obscurePassword,
                              validator: (v) => v == null || v.isEmpty
                                  ? "Password required"
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Use your registered owner credentials",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9B98B3),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        buttonColor,
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: buttonColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 6,
                                      ),
                                      child: const Text(
                                        "LOGIN",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
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
                                  color: Color(0xFFB0AFC5),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "Secure access for owners only",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFB0AFC5),
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: primaryOwnerColor.withOpacity(0.8)),
      floatingLabelStyle: const TextStyle(color: primaryOwnerColor),
      filled: true,
      fillColor: faintBackground,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
        borderSide: BorderSide(color: primaryOwnerColor, width: 2),
      ),
    );
  }
}
