import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/models/request.dart';
import 'package:internal_request_app/domain/models/request_record.dart';
import 'package:internal_request_app/domain/models/requester_requests.dart';

abstract interface class RequestRepository {
  Future<Result<RequestRecord>> createRequest(Request request);

  Future<Result<RequesterRequests>> getRequestsForRequester(String requesterId);
}
