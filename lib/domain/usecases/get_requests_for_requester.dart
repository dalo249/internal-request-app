import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/errors/get_requests_exception.dart';
import 'package:internal_request_app/domain/models/requester_requests.dart';
import 'package:internal_request_app/domain/repositories/request_repository.dart';

final class GetRequestsForRequester {
  GetRequestsForRequester(this._requestRepository);

  final RequestRepository _requestRepository;

  Future<Result<RequesterRequests>> call(String requesterId) {
    if (requesterId.trim().isEmpty) {
      return Future.value(
        Result.error(
          const GetRequestsException('No se identificó al usuario.'),
        ),
      );
    }

    return _requestRepository.getRequestsForRequester(requesterId);
  }
}
