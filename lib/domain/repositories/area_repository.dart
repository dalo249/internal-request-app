import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/models/area.dart';

abstract interface class AreaRepository {
  Future<Result<List<Area>>> getAreas();
}