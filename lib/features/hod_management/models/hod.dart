class Hod {
  const Hod({
    required this.id,
    required this.hodCode,
    required this.name,
    required this.email,
    required this.college,
    required this.department,
    required this.isActive,
  });

  final String id;
  final String hodCode;
  final String name;
  final String email;
  final String college;
  final String department;
  final bool isActive;

  String get displayHodCode => hodCode.isEmpty ? '-' : hodCode;

  factory Hod.fromMap(Map<String, dynamic> data) {
    return Hod(
      id: (data['id'] ?? '').toString(),
      hodCode: (data['hod_code'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      college: (data['college'] ?? '').toString(),
      department: (data['department'] ?? '').toString(),
      isActive: data['is_active'] == true,
    );
  }
}
