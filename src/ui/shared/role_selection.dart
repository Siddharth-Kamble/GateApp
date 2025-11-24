import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

// --- Theme Constants ---
const Color primaryBlue = Color(0xFF42A5F5); // Soft primary blue
const Color faintBackground = Color(0xFFF9F9FB); // Very light background
const Color accentColor = Color(0xFF00ACC1); // A nice secondary color

// --- RoleSelectionPage (Enhanced Look & Reordered) ---
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Header/Instruction Section ---
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

              // --- Role Buttons (Reordered) ---

              // 1. COMPANY OWNER
              RoleButton(
                label: 'Company Owner View',
                role: 'owner',
                icon: Icons.business_center_outlined,
                color: Colors.deepOrange,
              ),
              const SizedBox(height: 16),

              // 2. ADMIN
              RoleButton(
                label: 'Admin Console',
                role: 'admin',
                icon: Icons.admin_panel_settings_outlined,
                color: primaryBlue,
              ),
              const SizedBox(height: 16),

              // 3. SECURITY GUARD
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

// --- Enhanced RoleButton Widget ---
class RoleButton extends StatelessWidget {
  final String label;
  final String role;
  final IconData icon;
  final Color color;

  const RoleButton({
    super.key,
    required this.label,
    required this.role,
    required this.icon,
    required this.color,
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
            color: color.withOpacity(
              0.3,
            ), // Soft shadow matching the button color
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color, // Use the distinct color
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0, // Shadow is handled by the Container
        ),
        onPressed: () {
          // 1. Log in (Simulated)
          auth.loginAs(role);

          // 2. Navigate based on role
          if (role == 'owner') {
            Navigator.pushReplacementNamed(
              context,
              '/owner',
            ); // Navigate to Owner first
          } else if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else if (role == 'guard') {
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
