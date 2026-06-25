class DepartmentCatalog {
  const DepartmentCatalog._();

  static const String computerScience = 'Computer Science (CS)';
  static const String artificialIntelligenceAndDataScience =
      'Artificial Intelligence & Data Science (AI&DS)';

  static const List<String> options = [
    computerScience,
    artificialIntelligenceAndDataScience,
  ];

  static String canonicalValue(String value) {
    final normalized = _normalize(value);
    if (_computerScienceAliases.contains(normalized)) {
      return computerScience;
    }
    if (_aiAndDataScienceAliases.contains(normalized)) {
      return artificialIntelligenceAndDataScience;
    }
    return value.trim();
  }

  static String displayName(String value, {String fallback = ''}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    return canonicalValue(trimmed);
  }

  static bool matches(String first, String second) {
    final firstCanonical = canonicalValue(first);
    final secondCanonical = canonicalValue(second);
    return _normalize(firstCanonical) == _normalize(secondCanonical);
  }

  static const Set<String> _computerScienceAliases = {
    'cs',
    'cse',
    'computerscience',
    'computersciencecs',
    'computerengineering',
    'computerengineeringcs',
  };

  static const Set<String> _aiAndDataScienceAliases = {
    'aids',
    'aianddatascience',
    'aianddatascienceaids',
    'artificialintelligenceanddatascience',
    'artificialintelligenceanddatascienceaids',
  };

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}
