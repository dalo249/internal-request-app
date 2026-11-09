import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/models/area.dart';
import 'package:internal_request_app/domain/repositories/area_repository.dart';

final class GetAreas {
  GetAreas(this._areaRepository);

  final AreaRepository _areaRepository;

  Future<Result<List<Area>>> call() {
    return _areaRepository.getAreas();
  }
}
