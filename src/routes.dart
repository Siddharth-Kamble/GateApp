import 'package:flutter/widgets.dart';

import 'ui/shared/role_selection.dart';
import 'ui/admin/dashboard.dart';
import 'ui/guard/home.dart';
import 'ui/owner/home.dart';

class Routes {
  static const String roleSelection = '/';
  static const String adminDashboard = '/admin';
  static const String guardHome = '/guard';
  static const String ownerHome = '/owner';
  static const String manageUsers = '/admin/manage-users'; // <-- ADD ROUTE NAME

  static Map<String, WidgetBuilder> getRoutes() => {
    roleSelection: (_) => RoleSelectionPage(),
    adminDashboard: (_) => AdminDashboard(),
    guardHome: (_) => GuardHomePage(),
    ownerHome: (_) => OwnerDashboardPage(),
  };
}
