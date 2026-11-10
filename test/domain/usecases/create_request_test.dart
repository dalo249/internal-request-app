import 'package:flutter_test/flutter_test.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/enums/request_status.dart';
import 'package:internal_request_app/domain/errors/create_request_exception.dart';
import 'package:internal_request_app/domain/models/request.dart';
import 'package:internal_request_app/domain/models/request_record.dart';
import 'package:internal_request_app/domain/models/requester_requests.dart';
import 'package:internal_request_app/domain/repositories/request_repository.dart';
import 'package:internal_request_app/domain/usecases/create_request.dart';

void main() {
  group('CreateRequest', () {
    test('valida el UID antes de guardar', () async {
      final repository = _FakeRequestRepository();
      final useCase = CreateRequest(repository);

      final result = await useCase(
        requesterId: ' ',
        serviceId: 'service-1',
        description: 'El equipo no enciende',
      );

      expect(repository.createdRequest, isNull);
      expect(result, isA<Error<RequestRecord>>());
      expect(
        (result as Error<RequestRecord>).error,
        isA<CreateRequestValidationException>().having(
          (error) => error.error,
          'error',
          CreateRequestValidationError.requesterRequired,
        ),
      );
    });

    test('valida el servicio antes de guardar', () async {
      final repository = _FakeRequestRepository();
      final useCase = CreateRequest(repository);

      final result = await useCase(
        requesterId: 'user-1',
        serviceId: '',
        description: 'El equipo no enciende',
      );

      expect(repository.createdRequest, isNull);
      expect(
        (result as Error<RequestRecord>).error,
        isA<CreateRequestValidationException>().having(
          (error) => error.error,
          'error',
          CreateRequestValidationError.serviceRequired,
        ),
      );
    });

    test('valida que la descripción no esté vacía', () async {
      final repository = _FakeRequestRepository();
      final useCase = CreateRequest(repository);

      final result = await useCase(
        requesterId: 'user-1',
        serviceId: 'service-1',
        description: '  ',
      );

      expect(repository.createdRequest, isNull);
      expect(
        (result as Error<RequestRecord>).error,
        isA<CreateRequestValidationException>().having(
          (error) => error.error,
          'error',
          CreateRequestValidationError.descriptionRequired,
        ),
      );
    });

    test('crea y guarda la solicitud local pendiente', () async {
      final repository = _FakeRequestRepository();
      final useCase = CreateRequest(repository);

      final result = await useCase(
        requesterId: ' user-1 ',
        serviceId: ' service-1 ',
        description: '  El equipo no enciende.  ',
      );

      final request = repository.createdRequest!;
      expect(request.id, isNotEmpty);
      expect(request.requesterId, 'user-1');
      expect(request.serviceId, 'service-1');
      expect(request.description, 'El equipo no enciende.');
      expect(request.status, RequestStatus.requested);
      expect(request.progress, 0);
      expect(request.approverId, isNull);
      expect(request.executorId, isNull);
      expect(request.priority, isNull);
      expect(request.limitDate, isNull);

      expect(result, isA<Ok<RequestRecord>>());
      expect(
        (result as Ok<RequestRecord>).value.syncStatus,
        RequestSyncStatus.pending,
      );
    });

    test('propaga errores de persistencia del repositorio', () async {
      final failure = Exception('No fue posible guardar localmente');
      final repository = _FakeRequestRepository(result: Result.error(failure));
      final useCase = CreateRequest(repository);

      final result = await useCase(
        requesterId: 'user-1',
        serviceId: 'service-1',
        description: 'El equipo no enciende.',
      );

      expect(result, isA<Error<RequestRecord>>());
      expect((result as Error<RequestRecord>).error, same(failure));
    });
  });
}

class _FakeRequestRepository implements RequestRepository {
  _FakeRequestRepository({this.result});

  final Result<RequestRecord>? result;
  Request? createdRequest;

  @override
  Future<Result<RequestRecord>> createRequest(Request request) async {
    createdRequest = request;
    return result ??
        Result.ok(
          RequestRecord(
            request: request,
            syncStatus: RequestSyncStatus.pending,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        );
  }

  @override
  Future<Result<RequesterRequests>> getRequestsForRequester(
    String requesterId,
  ) {
    return Future.value(
      Result.ok(const RequesterRequests(records: [], isFromCache: false)),
    );
  }
}
