import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/errors/create_request_exception.dart';
import 'package:internal_request_app/domain/models/request.dart';
import 'package:internal_request_app/domain/models/request_record.dart';
import 'package:internal_request_app/domain/repositories/request_repository.dart';
import 'package:internal_request_app/domain/usecases/create_request.dart';
import 'package:internal_request_app/presentation/viewmodels/create_request_view_model.dart';

void main() {
  group('CreateRequestViewModel', () {
    test('expone éxito y el registro creado', () async {
      final repository = _FakeRequestRepository();
      final viewModel = CreateRequestViewModel(CreateRequest(repository));
      addTearDown(viewModel.dispose);

      await viewModel.createRequest(
        requesterId: 'user-1',
        serviceId: 'service-1',
        description: 'El equipo no enciende.',
      );

      expect(viewModel.state.status, CreateRequestStatus.success);
      expect(viewModel.state.record?.request.requesterId, 'user-1');
      expect(viewModel.state.record?.syncStatus, RequestSyncStatus.pending);
    });

    test('expone error de validación', () async {
      final repository = _FakeRequestRepository();
      final viewModel = CreateRequestViewModel(CreateRequest(repository));
      addTearDown(viewModel.dispose);

      await viewModel.createRequest(
        requesterId: 'user-1',
        serviceId: '',
        description: 'Descripción',
      );

      expect(viewModel.state.status, CreateRequestStatus.validationFailure);
      expect(
        viewModel.state.validationError,
        CreateRequestValidationError.serviceRequired,
      );
      expect(repository.createdRequests, isEmpty);
    });

    test('expone error de persistencia', () async {
      final repository = _FakeRequestRepository(
        result: Result.error(
          RequestPersistenceException(Exception('SQLite falló')),
        ),
      );
      final viewModel = CreateRequestViewModel(CreateRequest(repository));
      addTearDown(viewModel.dispose);

      await viewModel.createRequest(
        requesterId: 'user-1',
        serviceId: 'service-1',
        description: 'Descripción',
      );

      expect(viewModel.state.status, CreateRequestStatus.persistenceFailure);
      expect(
        viewModel.state.persistenceError,
        isA<RequestPersistenceException>(),
      );
    });

    test('ignora envíos adicionales mientras hay uno en curso', () async {
      final completer = Completer<Result<RequestRecord>>();
      final repository = _FakeRequestRepository(
        onCreate: () => completer.future,
      );
      final viewModel = CreateRequestViewModel(CreateRequest(repository));
      addTearDown(viewModel.dispose);

      final firstSubmission = viewModel.createRequest(
        requesterId: 'user-1',
        serviceId: 'service-1',
        description: 'Primera solicitud',
      );
      await Future<void>.delayed(Duration.zero);

      await viewModel.createRequest(
        requesterId: 'user-1',
        serviceId: 'service-2',
        description: 'Segunda solicitud',
      );

      expect(repository.createdRequests, hasLength(1));

      completer.complete(
        Result.ok(repository._record(repository.createdRequests.single)),
      );
      await firstSubmission;

      expect(viewModel.state.status, CreateRequestStatus.success);
      expect(repository.createdRequests, hasLength(1));
    });
  });
}

class _FakeRequestRepository implements RequestRepository {
  _FakeRequestRepository({this.result, this.onCreate});

  final Result<RequestRecord>? result;
  final Future<Result<RequestRecord>> Function()? onCreate;
  final List<Request> createdRequests = [];

  RequestRecord _record(Request request) {
    final now = DateTime(2026);
    return RequestRecord(
      request: request,
      syncStatus: RequestSyncStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<Result<RequestRecord>> createRequest(Request request) async {
    createdRequests.add(request);
    final create = onCreate;
    if (create != null) return create();

    return result ?? Result.ok(_record(request));
  }

  @override
  Future<List<RequestRecord>> getRequestsForRequester(
    String requesterId,
  ) async {
    return [];
  }
}
