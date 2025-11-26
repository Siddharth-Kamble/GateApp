import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminLoginService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String cacheRole = 'admin_role';
  static const String cacheIsActive = 'admin_isActive';
  static const String cacheUID = 'admin_uid';

  /// Optimized login function
  Future<bool> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      User? user = _auth.currentUser;
      if (user == null) {
        // Only network call if user not cached
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = userCredential.user;
        if (user == null) throw Exception("Authentication failed.");
      }

      // Check cache
      String? cachedUID = prefs.getString(cacheUID);
      String? cachedRole = prefs.getString(cacheRole);
      bool? cachedIsActive = prefs.getBool(cacheIsActive);

      if (cachedUID == user.uid &&
          cachedRole == 'admin' &&
          cachedIsActive == true) {
        return true; // Instant login
      }

      // Fetch only admin document
      DocumentSnapshot doc = await _firestore
          .collection('admin_users')
          .doc(user.uid)
          .get();
      if (!doc.exists) throw Exception("Admin not found.");

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['role'] != 'admin') throw Exception("Access denied.");
      if (data['isActive'] != true) throw Exception("Admin inactive.");

      // Cache for future logins
      await prefs.setString(cacheUID, user.uid);
      await prefs.setString(cacheRole, data['role']);
      await prefs.setBool(cacheIsActive, data['isActive']);

      return true;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  Future<void> logoutAdmin() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cacheUID);
    await prefs.remove(cacheRole);
    await prefs.remove(cacheIsActive);
  }
}
