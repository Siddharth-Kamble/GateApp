import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manage_users.dart';

const Color primaryBlue = Color(0xFF42A5F5);
const Color faintBackground = Color(0xFFF9F9FB);
const double cardRadius = 20.0;

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users'); // Collection for all users

  List<Map<String, dynamic>> users = [];
  bool loadingUsers = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      QuerySnapshot snapshot = await usersCollection.get();
      setState(() {
        users = snapshot.docs
            .map((doc) => doc.data()! as Map<String, dynamic>)
            .toList();
        loadingUsers = false;
      });
    } catch (e) {
      // Firestore error fallback
      setState(() {
        users = [
          {
            "name": "Default Admin",
            "username": "admin",
            "role": "admin",
            "password": "admin123",
            "mobile": "0000000000",
          },
        ];
        loadingUsers = false;
      });
    }
  }

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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManageUsersPage(usersCollection: usersCollection),
            ),
          );
        },
        label: const Text('Manage Users'),
        icon: const Icon(Icons.person_add_alt_1),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
      body: loadingUsers
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(cardRadius),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(user['name'] ?? 'No Name'),
                      subtitle: Text(
                        "Username: ${user['username'] ?? ''}\nRole: ${user['role'] ?? ''}\nPassword: ${user['password'] ?? ''}\nMobile: ${user['mobile'] ?? ''}",
                      ),
                      leading: const Icon(Icons.person, color: primaryBlue),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
