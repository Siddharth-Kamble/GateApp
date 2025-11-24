import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/ui/admin/manage_users.dart'
    show ManageUsersPage;
// Assuming the ManageUsersPage is imported correctly

// --- Soft Shadow Style Constants ---
const Color primaryBlue = Color(0xFF42A5F5);
const Color faintBackground = Color(0xFFF9F9FB);
const double cardRadius = 20.0;

// Soft Shadow definition
final List<BoxShadow> softShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 15,
    offset: const Offset(0, 8),
  ),
  BoxShadow(
    color: Colors.white.withOpacity(0.7),
    blurRadius: 10,
    offset: const Offset(-5, -5),
  ),
];

// --- Data Model for Admin User ---
class AdminUser {
  final String name;
  final String username;
  final String role;
  final String maskedPassword;
  final bool isActive;

  const AdminUser({
    required this.name,
    required this.username,
    required this.role,
    required this.maskedPassword,
    required this.isActive,
  });
}

// --- Dashboard Metric Card (Helper widget) ---
class DashboardMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color cardColor;

  const DashboardMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: Colors.white, size: 32),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
// ----------------------------------------------------------------

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // Simulated User Data List (Password field is masked for security)
  final List<AdminUser> _users = const [
    AdminUser(
      name: 'John Doe (Owner)',
      username: 'john.owner',
      role: 'Owner',
      maskedPassword: '*****',
      isActive: true,
    ),
    AdminUser(
      name: 'Guard Team Lead',
      username: 'guard.lead',
      role: 'Guard',
      maskedPassword: '*****',
      isActive: true,
    ),
    AdminUser(
      name: 'Maintenance Manager',
      username: 'maint.mgr',
      role: 'Staff',
      maskedPassword: '*****',
      isActive: true,
    ),
    AdminUser(
      name: 'Inactive Guard',
      username: 'guard.inactive',
      role: 'Guard',
      maskedPassword: '*****',
      isActive: false,
    ),
    AdminUser(
      name: 'Jane Smith',
      username: 'jane.s',
      role: 'Owner',
      maskedPassword: '*****',
      isActive: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: faintBackground,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
        ),
        backgroundColor: faintBackground,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        centerTitle: false,
      ),
      // CONNECTED FAB: Navigates to ManageUsersPage
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ManageUsersPage()),
          );
        },
        label: const Text('Manage Users'),
        icon: const Icon(Icons.person_add_alt_1),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // --- Metric Cards (Grid Layout) ---
            _buildMetricGrid(),

            const SizedBox(height: 40),

            // --- USER LIST Section Header (Updated) ---
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                'System Users and Credentials',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // --- User List (Replaced Action List) ---
            _buildUserList(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // Helper method for the Metric Grid (Updated to show Total Users)
  Widget _buildMetricGrid() {
    // Calculate total users from the simulated data
    final totalUsers = _users.length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      childAspectRatio: 1.05,
      children: [
        DashboardMetricCard(
          title: 'Visitors Today',
          value: '42',
          icon: Icons.people_alt_outlined,
          iconColor: Colors.white,
          cardColor: const Color(0xFF00ACC1), // Teal
        ),
        DashboardMetricCard(
          title: 'Total Vehicles',
          value: '19',
          icon: Icons.directions_car_filled_outlined,
          iconColor: Colors.white,
          cardColor: primaryBlue, // Blue
        ),
        DashboardMetricCard(
          title: 'Active Guards',
          value: '6',
          icon: Icons.security_outlined,
          iconColor: Colors.white,
          cardColor: const Color(0xFFFFB300), // Amber
        ),
        // 4. Changed to Total Users
        DashboardMetricCard(
          title: 'Total Users',
          value: totalUsers.toString(),
          icon: Icons.group_add_outlined,
          iconColor: Colors.white,
          cardColor: const Color(0xFF673AB7), // Deep Purple
        ),
      ],
    );
  }

  // NEW Helper method for the User List (Replaces _buildActionList)
  Widget _buildUserList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: softShadow,
      ),
      child: Column(
        children: [
          // Iterate over the simulated user list
          ..._users.map((user) {
            return Column(
              children: [
                _buildUserTile(user),
                // Add a divider after every tile except the last one
                if (user != _users.last) _buildActionDivider(),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  // NEW Helper method to build a single User Tile
  Widget _buildUserTile(AdminUser user) {
    final statusColor = user.isActive
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE53935);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: user.isActive
            ? primaryBlue.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        child: Icon(
          user.role == 'Owner' ? Icons.star_border : Icons.person_outline,
          color: primaryBlue,
        ),
      ),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Username: ${user.username}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          Text(
            'Password (Masked): ${user.maskedPassword}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
      trailing: Chip(
        label: Text(
          user.isActive ? 'Active' : 'Inactive',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        backgroundColor: statusColor,
      ),
      onTap: () {
        // Placeholder for navigation/action (e.g., Edit User)
        print('Tapped on user: ${user.name}');
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildActionDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
    );
  }
}
