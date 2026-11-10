import 'package:internal_request_app/domain/models/request.dart';

class RequestRecord {
  const RequestRecord({
    required this.request,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncError,
  });

  final Request request;
  final RequestSyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastSyncError;
}

enum RequestSyncStatus {
  pending,
  synced,
  conflict;

  static RequestSyncStatus fromValue(String value) {
    for (final status in RequestSyncStatus.values) {
      if (status.name == value) return status;
    }

    throw FormatException('Estado de sincronización no reconocido: "$value".');
  }
}
