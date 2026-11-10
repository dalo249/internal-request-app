import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/models/request.dart';
import 'package:internal_request_app/domain/models/request_record.dart';

abstract interface class RequestRepository {
  Future<Result<RequestRecord>> createRequest(Request request);

  Future<List<RequestRecord>> getRequestsForRequester(String requesterId);
}
