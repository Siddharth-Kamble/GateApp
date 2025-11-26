import 'dart:async' show TimeoutException;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminLoginService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String cacheRole = 'admin_role';
  static const String cacheIsActive = 'admin_isActive';
  static const String cacheUID = 'admin_uid';

  /// Optimized login with debug prints and timeout
  Future<bool> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      print("Starting admin login...");

      // 1️⃣ Try using cached Firebase user
      User? user = _auth.currentUser;
      if (user != null) {
        print("Found cached Firebase user: ${user.uid}");
      } else {
        print("No cached user, signing in...");
        // Timeout after 10 seconds
        UserCredential userCredential = await _auth
            .signInWithEmailAndPassword(email: email, password: password)
            .timeout(Duration(seconds: 10));
        user = userCredential.user;
        if (user == null) throw Exception("Authentication failed.");
        print("Firebase login completed! UID: ${user.uid}");
      }

      // 2️⃣ Check cached admin info
      final prefs = await SharedPreferences.getInstance();
      String? cachedUID = prefs.getString(cacheUID);
      String? cachedRole = prefs.getString(cacheRole);
      bool? cachedIsActive = prefs.getBool(cacheIsActive);

      if (cachedUID == user.uid &&
          cachedRole == 'admin' &&
          cachedIsActive == true) {
        print("Admin login via cache!");
        return true;
      }

      // 3️⃣ Fetch admin document from Firestore
      print("Fetching admin document from Firestore...");
      DocumentSnapshot doc = await _firestore
          .collection('admin_users')
          .doc(user.uid)
          .get()
          .timeout(Duration(seconds: 10));

      if (!doc.exists) throw Exception("Admin record not found.");

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      if (data['role'] != 'admin') throw Exception("Access denied: Not admin.");
      if (data['isActive'] != true) throw Exception("Admin account inactive.");

      // 4️⃣ Cache admin info
      await prefs.setString(cacheUID, user.uid);
      await prefs.setString(cacheRole, data['role']);
      await prefs.setBool(cacheIsActive, data['isActive']);

      print("Admin login successful and cache saved!");
      return true;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.code} - ${e.message}");
      return false;
    } on TimeoutException {
      print("Login timed out. Check your network!");
      return false;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  /// Logout function clears cache
  Future<void> logoutAdmin() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cacheUID);
    await prefs.remove(cacheRole);
    await prefs.remove(cacheIsActive);
    print("Admin logged out and cache cleared.");
  }
}
