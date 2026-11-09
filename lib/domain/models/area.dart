import 'service.dart';

final class Area {
  const Area({
    required this.id,
    required this.name,
    required this.description,
    required this.services,
  });

  final String id;
  final String name;
  final String description;
  final List<Service> services;

  factory Area.fromJson(Map<String, dynamic> json) {
    final id = _requiredString(json, 'id');
    final name = _requiredString(json, 'name');
    final description = _requiredString(json, 'description');
    final servicesValue = json['services'];

    if (servicesValue is! List) {
      throw const FormatException('El campo "services" debe ser una lista.');
    }

    final services = servicesValue.map((service) {
      if (service is! Map<String, dynamic>) {
        throw const FormatException(
          'Cada elemento de "services" debe ser un objeto JSON.',
        );
      }

      return Service.fromJson(service);
    }).toList();

    return Area(
      id: id,
      name: name,
      description: description,
      services: services,
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
      'name': name,
      'description': description,
      'services': services.map((service) => service.toJson()).toList(),
    };
  }
}
