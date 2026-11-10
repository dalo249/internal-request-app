import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/models/request.dart';

final class RequestRemoteDataSource {
  RequestRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('requests');

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
}
