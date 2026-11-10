import 'package:flutter_test/flutter_test.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/errors/get_requests_exception.dart';
import 'package:internal_request_app/domain/models/request.dart';
import 'package:internal_request_app/domain/models/request_record.dart';
import 'package:internal_request_app/domain/models/requester_requests.dart';
import 'package:internal_request_app/domain/repositories/request_repository.dart';
import 'package:internal_request_app/domain/usecases/get_requests_for_requester.dart';
import 'package:internal_request_app/presentation/viewmodels/my_requests_view_model.dart';

void main() {
  group('MyRequestsViewModel', () {
    test('expone estado vacío cuando no hay solicitudes', () async {
      final viewModel = MyRequestsViewModel(
        GetRequestsForRequester(_FakeRequestRepository()),
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadRequests('user-1');

      expect(viewModel.state.status, MyRequestsStatus.empty);
    });

    test('expone error cuando falla la consulta', () async {
      final repository = _FakeRequestRepository(
        result: Result.error(
          GetRequestsException('No se pudieron cargar las solicitudes.'),
        ),
      );
      final viewModel = MyRequestsViewModel(
        GetRequestsForRequester(repository),
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadRequests('user-1');

      expect(viewModel.state.status, MyRequestsStatus.error);
      expect(viewModel.state.failure?.message, contains('No se pudieron'));
    });
  });
}

class _FakeRequestRepository implements RequestRepository {
  _FakeRequestRepository({this.result});

  final Result<RequesterRequests>? result;

  @override
  Future<Result<RequestRecord>> createRequest(Request request) {
    throw UnimplementedError();
  }

  @override
  Future<Result<RequesterRequests>> getRequestsForRequester(
    String requesterId,
  ) async {
    return result ??
        Result.ok(const RequesterRequests(records: [], isFromCache: false));
  }
}
