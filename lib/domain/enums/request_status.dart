enum RequestStatus {
  requested('solicitada'),  
  approved('autorizada'),
  inProgress('en proceso'),
  completed('por validar'),
  closed('cerrada'),
  rejected('rechazada');


  const RequestStatus(this.value);

  final String value;

  static RequestStatus fromValue(String value) {
    for (final status in RequestStatus.values) {
      if (status.value == value) return status;
    }

    throw FormatException('Estado de solicitud no reconocido: "$value".');
  }
}