class College {
  const College({
    required this.id,
    required this.name,
    required this.code,
    required this.city,
    required this.state,
    required this.status,
    required this.raw,
  });

  final String id;
  final String name;
  final String code;
  final String city;
  final String state;
  final String status;
  final Map<String, dynamic> raw;

  bool get isActive {
    final value = raw['is_active'];
    if (value is bool) return value;
    return status.toLowerCase() == 'active';
  }

  String get label {
    if (code.isEmpty) return name;
    return '$name ($code)';
  }

  factory College.fromMap(Map<String, dynamic> data) {
    String text(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return '';
    }

    return College(
      id: text(['id']),
      name: text(['college_name']),
      code: text(['college_code']),
      city: text(['city']),
      state: text(['state']),
      status: text(['status']).isEmpty ? 'Active' : text(['status']),
      raw: Map<String, dynamic>.from(data),
    );
  }
}
