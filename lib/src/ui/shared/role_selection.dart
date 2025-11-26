import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_login.dart';

const Color primaryBlue = Color(0xFF42A5F5);
const Color faintBackground = Color(0xFFF9F9FB);
const Color accentColor = Color(0xFF00ACC1);

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: faintBackground,
      appBar: AppBar(
        title: const Text(
          'Select Your Role',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 1,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.security_rounded, size: 60, color: primaryBlue),
              const SizedBox(height: 15),
              const Text(
                'Please identify your access level.',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your selection determines the dashboard and features available to you.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),

              RoleButton(
                label: 'Company Owner View',
                role: 'owner',
                icon: Icons.business_center_outlined,
                color: Colors.deepOrange,
              ),
              const SizedBox(height: 16),

              RoleButton(
                label: 'Admin Console',
                role: 'admin',
                icon: Icons.admin_panel_settings_outlined,
                color: primaryBlue,
                navigateToLogin: true,
              ),
              const SizedBox(height: 16),

              RoleButton(
                label: 'Security Guard Interface',
                role: 'guard',
                icon: Icons.security,
                color: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleButton extends StatelessWidget {
  final String label;
  final String role;
  final IconData icon;
  final Color color;
  final bool navigateToLogin;

  const RoleButton({
    super.key,
    required this.label,
    required this.role,
    required this.icon,
    required this.color,
    this.navigateToLogin = false,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: () {
          if (navigateToLogin && role == 'admin') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminLoginPage()),
            );
            return;
          }
          auth.loginAs(role);
          if (role == 'owner') {
            Navigator.pushReplacementNamed(context, '/owner');
          }
          if (role == 'guard') {
            Navigator.pushReplacementNamed(context, '/guard');
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 15),
            Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
