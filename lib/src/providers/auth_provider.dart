import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? _role;

  String? get role => _role; // Fixes the 'role' error

  void loginAs(String role) {
    _role = role;
    notifyListeners();
  }

  void logout() {
    _role = null;
    notifyListeners();
  }
}
