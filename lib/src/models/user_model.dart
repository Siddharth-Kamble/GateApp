class UserModel {
  String? uid; // Firestore document ID
  String? name; // Full name
  String? email; // Email or username
  String? password; // Password (store hashed in production)
  String? role; // 'admin', 'guard', 'owner', etc.
  bool? isActive; // true if user is active

  UserModel({
    this.uid,
    this.name,
    this.email,
    this.password,
    this.role,
    this.isActive,
  });

  // Create UserModel from Firestore map
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? 'user',
      isActive: map['isActive'] ?? true,
    );
  }

  // Convert UserModel to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'isActive': isActive,
    };
  }
}
