import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/enums/request_priority.dart';
import 'package:internal_request_app/domain/enums/request_status.dart';
import 'package:internal_request_app/domain/models/request.dart';
import 'package:internal_request_app/domain/models/request_record.dart';

final class RequestRemoteDataSource {
  RequestRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('requests');

  Future<Result<List<RequestRecord>>> getRequestsForRequester(
    String requesterId,
  ) async {
    try {
      final snapshot = await _requests
          .where('requesterId', isEqualTo: requesterId)
          .get();
      final records = snapshot.docs.map(_toRequestRecord).toList()
        ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
      return Result.ok(records);
    } on FirebaseException catch (exception) {
      return Result.error(exception);
    } on Exception catch (exception) {
      return Result.error(exception);
    }
  }

  Future<Result<void>> createRequest(
    Request request, {
    required String approverId,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      await _requests.doc(request.id).set({
        'id': request.id,
        'serviceId': request.serviceId,
        'requesterId': request.requesterId,
        'description': request.description,
        'status': request.status.value,
        'progress': request.progress,
        'approverId': approverId,
        'executorId': null,
        'priority': null,
        'limitDate': null,
        'createdAt': now,
        'updatedAt': now,
      });

      return Result.ok(null);
    } on FirebaseException catch (exception) {
      return Result.error(exception);
    } on Exception catch (exception) {
      return Result.error(exception);
    }
  }

  RequestRecord _toRequestRecord(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAt = _readDate(data, 'createdAt');
    final updatedAt = _readDate(data, 'updatedAt');
    final limitDate = _readNullableDate(data, 'limitDate');
    final progress = data['progress'];

    if (progress is! int || progress < 0 || progress > 100) {
      throw const FormatException('El avance de la solicitud no es válido.');
    }

    final priority = data['priority'];
    if (priority != null && priority is! String) {
      throw const FormatException('La prioridad de la solicitud no es válida.');
    }

    return RequestRecord(
      request: Request(
        id: document.id,
        serviceId: _readString(data, 'serviceId'),
        requesterId: _readString(data, 'requesterId'),
        description: _readString(data, 'description'),
        status: RequestStatus.fromValue(_readString(data, 'status')),
        progress: progress,
        approverId: _readNullableString(data, 'approverId'),
        executorId: _readNullableString(data, 'executorId'),
        priority: priority == null
            ? null
            : RequestPriority.fromValue(priority as String),
        limitDate: limitDate,
      ),
      syncStatus: RequestSyncStatus.synced,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String _readString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('El campo "$key" no es válido.');
    }
    return value;
  }

  String? _readNullableString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('El campo "$key" no es válido.');
    }
    return value;
  }

  DateTime _readDate(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    throw FormatException('El campo "$key" no contiene una fecha válida.');
  }

  DateTime? _readNullableDate(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    throw FormatException('El campo "$key" no contiene una fecha válida.');
  }
}
