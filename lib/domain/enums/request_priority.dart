enum RequestPriority {
  low('baja'),
  medium('media'),
  high('alta'),
  urgent('urgente');

  const RequestPriority(this.value);

  final String value;

  static RequestPriority fromValue(String value) {
    for (final priority in RequestPriority.values) {
      if (priority.value == value) return priority;
    }

    throw FormatException('Prioridad de solicitud no reconocida: "$value".');
  }
}
