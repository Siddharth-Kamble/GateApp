

import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/ui/guard/guard_login.dart';
import 'package:flutter_application_1/src/ui/admin/admin_login.dart';
import 'package:flutter_application_1/src/ui/owner/owner_login_page.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

// ======================= Professional Color Palette =======================

// Owner
const Color ownerColorStart = Color.fromARGB(199, 87, 88, 88);
const Color ownerColorEnd = Color.fromARGB(255, 153, 153, 154);

// Admin
const Color adminColorStart = Color.fromARGB(255, 33, 104, 236);
const Color adminColorEnd = Color.fromARGB(255, 67, 182, 249);

// Guard
const Color guardColorStart = Color(0xFFFFB84D);
const Color guardColorEnd = Color(0xFFE57A00);

// Real working background gray
const Color appBackgroundGray = Color.fromARGB(255, 237, 237, 239);

const Color darkTextColor = Color(0xFF212121);

// ======================= ROLE SELECTION PAGE =======================

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundGray,
      body: SafeArea(
        child: Container(
          color: appBackgroundGray,
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double maxWidth = constraints.maxWidth > 700
                    ? 520
                    : constraints.maxWidth;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),

                          // -------- Logo --------
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 80,
                                width: 150,
                                child: Image.asset(
                                  "lib/src/assets/odlfs.jpg",
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "MyGate",
                                    style: GoogleFonts.montserrat(
                                      fontSize: 52,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                      height: 1.0,
                                      color: const Color(0xFF0F0F0F),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          const SizedBox(height: 32),

                          // -------- Main Card --------
                          Card(
                            color: Colors.white,
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    "Choose Role",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: darkTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    "You can switch roles later from the settings.",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black45,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // OWNER
                                  WideRoleButton(
                                    label: "Company Owner View",
                                    subLabel: "Management & Overview",
                                    role: "owner",
                                    icon: Icons.business_center_outlined,
                                    gradientColors: const [
                                      ownerColorStart,
                                      ownerColorEnd,
                                    ],
                                    navigateToLogin: true,
                                  ),
                                  const SizedBox(height: 14),

                                  // ADMIN
                                  WideRoleButton(
                                    label: "Admin Console",
                                    subLabel: "System Configuration & Users",
                                    role: "admin",
                                    icon: Icons.admin_panel_settings_outlined,
                                    gradientColors: const [
                                      adminColorStart,
                                      adminColorEnd,
                                    ],
                                    navigateToLogin: true,
                                  ),
                                  const SizedBox(height: 14),

                                  // GUARD
                                  WideRoleButton(
                                    label: "Security Guard Interface",
                                    subLabel: "Visitor & Entry Control",
                                    role: "guard",
                                    icon: Icons.security,
                                    gradientColors: const [
                                      guardColorStart,
                                      guardColorEnd,
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // -------- FOOTER --------
                          const Text(
                            "@ONE DEO LEELA FACADE SYSTEMS PVT LTD",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 0.5,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ======================= WIDE ROLE BUTTON =======================

class WideRoleButton extends StatelessWidget {
  final String label;
  final String subLabel;
  final String role;
  final IconData icon;
  final List<Color> gradientColors;
  final bool navigateToLogin;

  const WideRoleButton({
    super.key,
    required this.label,
    required this.subLabel,
    required this.role,
    required this.icon,
    required this.gradientColors,
    this.navigateToLogin = false,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (navigateToLogin && role == "admin") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginPage()),
              );
              return;
            }

            if (role == "guard") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GuardLoginPage()),
              );
              return;
            }

            if (navigateToLogin && role == "owner") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OwnerLoginPage()),
              );
              return;
            }

            auth.loginAs(role);
          },
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.last.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
