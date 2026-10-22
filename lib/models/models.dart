class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'user' | 'student' | 'farmer' | 'agriculturist' | 'researcher' | 'admin'
  final String? firstName;
  final String? lastName;
  final DateTime? birthday;
  final String? gender;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    this.birthday,
    this.gender,
  });

  String get roleLabel {
    switch (role) {
      case 'researcher':
        return 'Extension Worker / Researcher';
      case 'admin':
        return 'Administrator';
      case 'student':
        return 'Student';
      case 'farmer':
        return 'Farmer';
      case 'agriculturist':
        return 'Agriculturist';
      default:
        return 'Registered User';
    }
  }

  bool get isAdmin => role == 'admin';
  bool get isResearcher => role == 'researcher';
}

class Variety {
  final String id;
  final String name;
  final String description;
  final bool active;

  const Variety({
    required this.id,
    required this.name,
    required this.description,
    this.active = true,
  });

  Variety copyWith({String? name, String? description, bool? active}) => Variety(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        active: active ?? this.active,
      );
}

class Prediction {
  final String id;
  final String userId;
  final String? variety;
  final double? confidence;
  final DateTime createdAt;
  final bool failed;

  const Prediction({
    required this.id,
    required this.userId,
    this.variety,
    this.confidence,
    required this.createdAt,
    this.failed = false,
  });
}
