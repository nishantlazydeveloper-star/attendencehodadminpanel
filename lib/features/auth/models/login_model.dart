class AdminModel {
  final String uid;
  final String email;
  final String role;
  final bool isActive;

  AdminModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.isActive,
  });

  factory AdminModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AdminModel(
      uid: documentId,
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      isActive: map['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'role': role, 'is_active': isActive};
  }
}
