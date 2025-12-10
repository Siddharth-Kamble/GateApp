import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/src/ui/admin/userForm.dart'
    show AddNewUserPage;

// CONNECTING IMPORT: This line links the two pages

// --- Constants (Matching the theme) ---
const Color primaryBlue = Color(0xFF42A5F5);
const Color faintBackground = Color(0xFFF9F9FB);
const Color deleteColor = Color(0xFFD32F2F); // Red for delete action

// --- User Data Structure ---
class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final Color roleColor;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roleColor,
  });
}

// ----------------------------------------------------------------
// -------------------- MANAGE USERS PAGE -------------------------
// ----------------------------------------------------------------

class ManageUsersPage extends StatelessWidget {
  final CollectionReference<Object?> usersCollection;

  ManageUsersPage({super.key, required this.usersCollection});

  // Sample User List
  final List<User> users = [
    User(
      id: '1',
      name: 'John Doe',
      email: 'john.doe@admin.com',
      role: 'System Admin',
      roleColor: primaryBlue,
    ),
    User(
      id: '2',
      name: 'Jane Smith',
      email: 'jane.smith@guard.com',
      role: 'Security Guard',
      roleColor: Colors.deepOrange,
    ),
    User(
      id: '3',
      name: 'Mike Johnson',
      email: 'mike.j@staff.com',
      role: 'Staff',
      roleColor: Colors.grey,
    ),
    User(
      id: '4',
      name: 'Alice Brown',
      email: 'alice.b@guard.com',
      role: 'Security Guard',
      roleColor: Colors.deepOrange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: faintBackground,
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 1,
      ),

      // Floating Action Button for CREATE (Add User)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _handleCreateUser(context), // Pass usersCollection here
        label: const Text('Add New User'),
        icon: const Icon(Icons.person_add_alt_1),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Active Users (${users.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryBlue,
              ),
            ),
          ),

          // --- User List ---
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: users.map((user) {
                return _buildUserTile(context, user);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 💡 NAVIGATION IMPLEMENTATION
  void _handleCreateUser(BuildContext context) {
    Navigator.push(
      context,
      // Pass the required usersCollection to AddNewUserPage
      MaterialPageRoute(
        builder: (context) => AddNewUserPage(usersCollection: usersCollection),
      ),
    );
  }

  // --- Widget for each User Tile (Update/Delete/Role) ---
  Widget _buildUserTile(BuildContext context, User user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: user.roleColor.withOpacity(0.15),
        child: Icon(Icons.person, color: user.roleColor),
      ),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.email,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: user.roleColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.role,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: primaryBlue),
            tooltip: 'Edit User & Role',
            onPressed: () {
              // Placeholder for Update/Edit navigation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Action: Placeholder for Edit User Screen'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: deleteColor),
            tooltip: 'Delete User',
            onPressed: () => _handleDeleteUser(context, user),
          ),
        ],
      ),
    );
  }

  void _handleDeleteUser(BuildContext context, User user) {
    // Show a confirmation dialog before deletion
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete user ${user.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User ${user.name} deleted successfully.'),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: deleteColor)),
          ),
        ],
      ),
    );
  }
}
