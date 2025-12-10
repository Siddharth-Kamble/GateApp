import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/src/ui/admin/userForm.dart'
    show AddNewUserPage;

// --- Global Constants ---
const Color primaryBlue = Color(0xFF42A5F5);
const Color faintBackground = Color(0xFFF4F5FB);
const double cardRadius = 20.0;
// ---

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  int _totalUsers = 0;
  int _activeUsers = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: faintBackground,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: faintBackground,
        foregroundColor: const Color(0xFF333333),
        centerTitle: false,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddNewUserPage(usersCollection: usersCollection),
            ),
          );
        },
        label: const Text('Add New User'),
        icon: const Icon(Icons.person_add_alt_1),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 6,
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: usersCollection.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final docs = snapshot.data!.docs;
              _totalUsers = docs.length;
              _activeUsers = docs
                  .where((d) =>
                      (d.data() as Map<String, dynamic>)['isActive'] == true)
                  .length;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Welcome / stats card
                _AdminOverviewHeader(
                  totalUsers: _totalUsers,
                  activeUsers: _activeUsers,
                ),

                const SizedBox(height: 20),

                const Text(
                  'User Accounts',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: _buildUserList(snapshot, theme),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserList(
    AsyncSnapshot<QuerySnapshot> snapshot,
    ThemeData theme,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: primaryBlue),
      );
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(
        child: Text(
          'No users found.\nTap “Add New User” to create one.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF777777),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: snapshot.data!.docs.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        DocumentSnapshot doc = snapshot.data!.docs[index];
        Map<String, dynamic> user = doc.data()! as Map<String, dynamic>;
        user['id'] = doc.id;

        return UserListItem(
          user: user,
          usersCollection: usersCollection,
        );
      },
    );
  }
}

// --- Header: overview card ---
class _AdminOverviewHeader extends StatelessWidget {
  final int totalUsers;
  final int activeUsers;

  const _AdminOverviewHeader({
    required this.totalUsers,
    required this.activeUsers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      child: Row(
        children: [
          const Icon(
            Icons.dashboard_customize_outlined,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '👋 Welcome back, Administrator',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage your user accounts efficiently.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _chip(
                      label: 'Total: $totalUsers',
                      icon: Icons.people_alt_outlined,
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      label: 'Active: $activeUsers',
                      icon: Icons.verified_user_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Reusable Widget for each User tile ---
class UserListItem extends StatelessWidget {
  final Map<String, dynamic> user;
  final CollectionReference usersCollection;

  const UserListItem({
    super.key,
    required this.user,
    required this.usersCollection,
  });

  Future<void> _deleteUser(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text("Delete user: ${user['name']} ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await usersCollection.doc(user['id']).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            SnackBar(content: Text('Failed to delete user: $e')),
          );
        }
      }
    }
  }

  void _editUser(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddNewUserPage(
          usersCollection: usersCollection,
          docId: user['id'],
          existingData: user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String role = (user['role'] ?? '').toString();
    final bool isActive = user['isActive'] == true;

    Color roleColor;
    IconData roleIcon;

    switch (role) {
      case 'admin':
        roleColor = Colors.deepOrange;
        roleIcon = Icons.verified_user;
        break;
      case 'owner':
        roleColor = Colors.purple;
        roleIcon = Icons.business_center;
        break;
      case 'guard':
        roleColor = Colors.teal;
        roleIcon = Icons.shield_outlined;
        break;
      default:
        roleColor = primaryBlue;
        roleIcon = Icons.person;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: roleColor.withOpacity(0.1),
              child: Icon(
                roleIcon,
                color: roleColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Middle content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? 'No Name',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user['email'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _smallChip(
                        label: role.isEmpty ? 'No Role' : role.toUpperCase(),
                        background: roleColor.withOpacity(0.12),
                        textColor: roleColor,
                      ),
                      const SizedBox(width: 8),
                      _smallChip(
                        label: isActive ? 'Active' : 'Inactive',
                        background: isActive
                            ? Colors.green.withOpacity(0.10)
                            : Colors.red.withOpacity(0.10),
                        textColor: isActive ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit User',
                  icon: const Icon(Icons.edit_outlined, color: primaryBlue),
                  onPressed: () => _editUser(context),
                ),
                IconButton(
                  tooltip: 'Delete User',
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent),
                  onPressed: () => _deleteUser(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallChip({
    required String label,
    required Color background,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
