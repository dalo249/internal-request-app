import '../enums/user_role.dart';

final class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.areaId,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String areaId;
  final DateTime? createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final uid = _requiredString(json, 'uid');
    final name = _requiredString(json, 'name');
    final email = _requiredString(json, 'email');
    final role = UserRole.fromValue(_requiredString(json, 'role'));
    final areaId = _requiredString(json, 'areaId');

    final createdAtValue = json['createdAt'];
    DateTime? createdAt;
    if (createdAtValue != null) {
      if (createdAtValue is! String || createdAtValue.trim().isEmpty) {
        throw const FormatException(
          'El campo "createdAt" debe ser una fecha ISO 8601 o null.',
        );
      }

      createdAt = DateTime.tryParse(createdAtValue);
      if (createdAt == null) {
        throw FormatException(
          'El campo "createdAt" no contiene una fecha valida: "$createdAtValue".',
        );
      }
    }

    return UserProfile(
      uid: uid,
      name: name,
      email: email,
      role: role,
      areaId: areaId,
      createdAt: createdAt,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw FormatException('El campo "$key" debe ser un String no vacio.');
    }

    return value.trim();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role.value,
      'areaId': areaId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
