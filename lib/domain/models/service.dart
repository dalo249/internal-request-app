final class Service {
  const Service({
    required this.id,
    required this.areaId,
    required this.name,
    required this.description,
    required this.estimatedDays,
  });

  final String id;
  final String areaId;
  final String name;
  final String description;
  final int estimatedDays;

  factory Service.fromJson(Map<String, dynamic> json) {
    final id = _requiredString(json, 'id');
    final areaId = _requiredString(json, 'areaId');
    final name = _requiredString(json, 'name');
    final description = _requiredString(json, 'description');
    final estimatedDaysValue = json['estimatedDays'];

    if (estimatedDaysValue is! int || estimatedDaysValue < 0) {
      throw const FormatException(
        'El campo "estimatedDays" debe ser un entero no negativo.',
      );
    }

    return Service(
      id: id,
      areaId: areaId,
      name: name,
      description: description,
      estimatedDays: estimatedDaysValue,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw FormatException('El campo "$key" debe ser un String no vacío.');
    }

    return value.trim();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'areaId': areaId,
      'name': name,
      'description': description,
      'estimatedDays': estimatedDays,
    };
  }
}
