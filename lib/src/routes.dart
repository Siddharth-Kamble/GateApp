// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/src/ui/admin/dashboard.dart'
    show AdminDashboard;
import 'package:flutter_application_1/src/ui/admin/manage_users.dart'
    show ManageUsersPage;
import 'package:flutter_application_1/src/ui/guard/home.dart'
    show GuardHomePage;
import 'package:flutter_application_1/src/ui/owner/home.dart'
    show OwnerDashboardPage;
import 'package:flutter_application_1/src/ui/shared/role_selection.dart'
    show RoleSelectionPage;

/// AdminGuard widget to protect admin-only pages
class AdminGuard extends StatelessWidget {
  final Widget child;
  const AdminGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    // For simplicity, assuming admin access is granted here
    // You can replace this with proper login/auth logic
    final isAdmin = true;

    if (!isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access Denied — Admins Only')),
      );
    }

    return child;
  }
}

class Routes {
  static const String roleSelection = '/';
  static const String adminDashboard = '/admin';
  static const String guardHome = '/guard';
  static const String ownerHome = '/owner';
  static const String manageUsers = '/admin/manage-users';

  /// Firestore collection reference for admin users
  static final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('admin_users');

  static Map<String, WidgetBuilder> getRoutes() => {
    roleSelection: (_) => const RoleSelectionPage(),
    adminDashboard: (_) => AdminGuard(child: AdminDashboard()),
    guardHome: (_) => GuardHomePage(),
    ownerHome: (_) => OwnerDashboardPage(),
    manageUsers: (_) => AdminGuard(
      child: ManageUsersPage(
        usersCollection: usersCollection, // Pass the collection here
      ),
    ),
  };
}
