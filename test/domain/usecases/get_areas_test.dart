import 'package:flutter_test/flutter_test.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/models/area.dart';
import 'package:internal_request_app/domain/repositories/area_repository.dart';
import 'package:internal_request_app/domain/usecases/get_areas.dart';

void main() {
  group('GetAreas', () {
    test('retorna las áreas del repositorio', () async {
      const areas = [
        Area(id: '1', name: 'Tecnología', description: 'Soporte', services: []),
      ];
      final repository = _FakeAreaRepository(Result.ok(areas));
      final useCase = GetAreas(repository);

      final result = await useCase();

      expect(result, isA<Ok<List<Area>>>());
      expect((result as Ok<List<Area>>).value, same(areas));
      expect(repository.callCount, 1);
    });

    test('propaga el error del repositorio', () async {
      final failure = Exception('Error del catálogo');
      final repository = _FakeAreaRepository(Result.error(failure));
      final useCase = GetAreas(repository);

      final result = await useCase();

      expect(result, isA<Error<List<Area>>>());
      expect((result as Error<List<Area>>).error, same(failure));
    });
  });
}

class _FakeAreaRepository implements AreaRepository {
  _FakeAreaRepository(this.result);

  final Result<List<Area>> result;
  int callCount = 0;

  @override
  Future<Result<List<Area>>> getAreas() async {
    callCount++;
    return result;
  }
}
