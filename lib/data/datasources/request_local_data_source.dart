import 'package:drift/drift.dart';
import 'package:internal_request_app/data/local/app_database.dart';
import 'package:internal_request_app/domain/enums/request_priority.dart';
import 'package:internal_request_app/domain/enums/request_status.dart';
import 'package:internal_request_app/domain/models/request.dart';
import 'package:internal_request_app/domain/models/request_record.dart';

class RequestLocalDataSource {
  RequestLocalDataSource(this.db);

  final AppDatabase db;

  RequestRecord _toDomain(RequestRow row) {
    return RequestRecord(
      request: Request(
        id: row.id,
        serviceId: row.serviceId,
        requesterId: row.requesterId,
        description: row.description,
        status: RequestStatus.fromValue(row.status),
        progress: row.progress,
        approverId: row.approverId,
        executorId: row.executorId,
        priority: row.priority == null
            ? null
            : RequestPriority.fromValue(row.priority!),
        limitDate: row.limitDate,
      ),
      syncStatus: RequestSyncStatus.fromValue(row.syncStatus),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastSyncError: row.lastSyncError,
    );
  }

  Future<RequestRecord> saveRequest(Request request) async {
    final now = DateTime.now();

    await db
        .into(db.requests)
        .insert(
          RequestsCompanion.insert(
            id: request.id,
            serviceId: request.serviceId,
            requesterId: request.requesterId,
            description: request.description,
            status: Value(request.status.value),
            progress: Value(request.progress),
            approverId: Value(request.approverId),
            executorId: Value(request.executorId),
            priority: Value(request.priority?.value),
            limitDate: Value(request.limitDate),
            createdAt: now,
            updatedAt: now,
            syncStatus: Value(RequestSyncStatus.pending.name),
            lastSyncError: const Value(null),
          ),
        );

    return RequestRecord(
      request: request,
      syncStatus: RequestSyncStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<List<RequestRecord>> getRequestsForRequester(
    String requesterId,
  ) async {
    final rows =
        await (db.select(db.requests)
              ..where((request) => request.requesterId.equals(requesterId))
              ..orderBy([(request) => OrderingTerm.desc(request.createdAt)]))
            .get();

    return rows.map(_toDomain).toList();
  }

  Future<List<RequestRecord>> getPendingRequests() async {
    final rows =
        await (db.select(db.requests)
              ..where(
                (request) =>
                    request.syncStatus.equals(RequestSyncStatus.pending.name),
              )
              ..orderBy([(request) => OrderingTerm.asc(request.createdAt)]))
            .get();

    return rows.map(_toDomain).toList();
  }

  Future<void> markRequestSynced(String requestId) async {
    final updatedRows =
        await (db.update(
          db.requests,
        )..where((request) => request.id.equals(requestId))).write(
          RequestsCompanion(
            syncStatus: Value(RequestSyncStatus.synced.name),
            lastSyncError: const Value(null),
            updatedAt: Value(DateTime.now()),
          ),
        );

    if (updatedRows == 0) {
      throw StateError('No existe la solicitud "$requestId" en Drift.');
    }
  }

  Future<RequestRecord> updateRequestAfterSync(
    String requestId, {
    required String approverId,
  }) async {
    final updatedRows =
        await (db.update(
          db.requests,
        )..where((request) => request.id.equals(requestId))).write(
          RequestsCompanion(
            approverId: Value(approverId),
            syncStatus: Value(RequestSyncStatus.synced.name),
            lastSyncError: const Value(null),
            updatedAt: Value(DateTime.now()),
          ),
        );

    if (updatedRows == 0) {
      throw StateError('No existe la solicitud "$requestId" en Drift.');
    }

    return _getRequestById(requestId);
  }

  Future<RequestRecord> recordPendingSyncError(
    String requestId,
    String reason,
  ) async {
    final updatedRows =
        await (db.update(
          db.requests,
        )..where((request) => request.id.equals(requestId))).write(
          RequestsCompanion(
            syncStatus: Value(RequestSyncStatus.pending.name),
            lastSyncError: Value(reason),
            updatedAt: Value(DateTime.now()),
          ),
        );

    if (updatedRows == 0) {
      throw StateError('No existe la solicitud "$requestId" en Drift.');
    }

    return _getRequestById(requestId);
  }

  Future<void> markRequestConflict(String requestId, String reason) async {
    final updatedRows =
        await (db.update(
          db.requests,
        )..where((request) => request.id.equals(requestId))).write(
          RequestsCompanion(
            syncStatus: Value(RequestSyncStatus.conflict.name),
            lastSyncError: Value(reason),
            updatedAt: Value(DateTime.now()),
          ),
        );

    if (updatedRows == 0) {
      throw StateError('No existe la solicitud "$requestId" en Drift.');
    }
  }

  Future<void> deleteRequest(String requestId) async {
    final deletedRows = await (db.delete(
      db.requests,
    )..where((request) => request.id.equals(requestId))).go();

    if (deletedRows == 0) {
      throw StateError('No existe la solicitud "$requestId" en Drift.');
    }
  }

  Future<RequestRecord> _getRequestById(String requestId) async {
    final row = await (db.select(
      db.requests,
    )..where((request) => request.id.equals(requestId))).getSingleOrNull();

    if (row == null) {
      throw StateError('No existe la solicitud "$requestId" en Drift.');
    }

    return _toDomain(row);
  }
}
