import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;

  User? get user => _user;
  bool get isLoggedIn => _user != null;

  void loginAs(String role) {
    // Mock login for demo. Replace with real API call.
    _user = User(id: 'u1', name: 'Demo $role', role: role);
    _token = 'mock-token';
    notifyListeners();
  }

  void logout() {
    _user = null;
    _token = null;
    notifyListeners();
  }
}
