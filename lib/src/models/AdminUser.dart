class AdminUser {
  final String id; // Firestore document ID
  final String name;
  final String username;
  final String role;
  final bool isActive;

  AdminUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'role': role,
      'isActive': isActive,
    };
  }

  factory AdminUser.fromMap(String id, Map<String, dynamic> map) {
    return AdminUser(
      id: id,
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      role: map['role'] ?? '',
      isActive: map['isActive'] ?? false,
    );
  }
}
