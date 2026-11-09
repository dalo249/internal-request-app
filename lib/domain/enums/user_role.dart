enum UserRole {
  employee('employee'),
  supervisor('supervisor'),
  executor('executor');

  const UserRole(this.value);

  final String value;

  static UserRole fromValue(String value) {
    for (final role in UserRole.values) {
      if (role.value == value) return role;
    }

    throw FormatException('Rol de usuario no reconocido: "$value".');
  }

  String get displayName => switch (this) {
    UserRole.employee => 'Employee',
    UserRole.supervisor => 'Supervisor',
    UserRole.executor => 'Executor',
  };
}
