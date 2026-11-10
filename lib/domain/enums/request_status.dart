enum RequestStatus {
  requested('requested'),
  approved('approved'),
  inProgress('inProgress'),
  completed('completed'),
  closed('closed'),
  rejected('rejected');

  const RequestStatus(this.value);

  final String value;

  static RequestStatus fromValue(String value) {
    for (final status in RequestStatus.values) {
      if (status.value == value) return status;
    }

    throw FormatException('Estado de solicitud no reconocido: "$value".');
  }
}
