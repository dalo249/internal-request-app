import 'package:internal_request_app/domain/models/request_record.dart';

final class RequesterRequests {
  const RequesterRequests({
    required this.records,
    required this.isFromCache,
    this.notice,
  });

  final List<RequestRecord> records;
  final bool isFromCache;
  final String? notice;
}
