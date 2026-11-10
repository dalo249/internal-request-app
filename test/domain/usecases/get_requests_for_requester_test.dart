import 'package:flutter_test/flutter_test.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/models/request.dart';
import 'package:internal_request_app/domain/models/request_record.dart';
import 'package:internal_request_app/domain/models/requester_requests.dart';
import 'package:internal_request_app/domain/repositories/request_repository.dart';
import 'package:internal_request_app/domain/usecases/get_requests_for_requester.dart';

void main() {
  group('GetRequestsForRequester', () {
    test('rechaza un UID vacío', () async {
      final repository = _FakeRequestRepository();

      final result = await GetRequestsForRequester(repository)(' ');

      expect(result, isA<Error<RequesterRequests>>());
      expect(repository.requesterId, isNull);
    });

    test('consulta el repositorio con el UID recibido', () async {
      final repository = _FakeRequestRepository();

      final result = await GetRequestsForRequester(repository)('user-1');

      expect(repository.requesterId, 'user-1');
      expect(result, isA<Ok<RequesterRequests>>());
    });
  });
}

class _FakeRequestRepository implements RequestRepository {
  String? requesterId;

  @override
  Future<Result<RequestRecord>> createRequest(Request request) {
    throw UnimplementedError();
  }

  @override
  Future<Result<RequesterRequests>> getRequestsForRequester(String id) async {
    requesterId = id;
    return Result.ok(const RequesterRequests(records: [], isFromCache: false));
  }
}
