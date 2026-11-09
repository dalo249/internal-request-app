import 'package:flutter_test/flutter_test.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/errors/area_catalog_failures.dart';
import 'package:internal_request_app/domain/models/area.dart';
import 'package:internal_request_app/domain/repositories/area_repository.dart';
import 'package:internal_request_app/domain/usecases/get_areas.dart';
import 'package:internal_request_app/presentation/viewmodels/area_catalog_view_model.dart';

void main() {
  group('AreaCatalogViewModel', () {
    test('expone las áreas cuando la consulta tiene éxito', () async {
      const areas = [
        Area(id: '1', name: 'Tecnología', description: 'Soporte', services: []),
      ];
      final repository = _FakeAreaRepository(Result.ok(areas));
      final viewModel = AreaCatalogViewModel(GetAreas(repository));
      addTearDown(viewModel.dispose);

      await viewModel.loadAreas();

      expect(viewModel.state.status, AreaCatalogStatus.loaded);
      expect(viewModel.state.areas, hasLength(1));
      expect(viewModel.state.areas.single, same(areas.single));
    });

    test('expone estado vacío cuando no hay áreas', () async {
      final repository = _FakeAreaRepository(Result.ok(const []));
      final viewModel = AreaCatalogViewModel(GetAreas(repository));
      addTearDown(viewModel.dispose);

      await viewModel.loadAreas();

      expect(viewModel.state.status, AreaCatalogStatus.empty);
      expect(viewModel.state.areas, isEmpty);
    });

    test('expone el fallo tipado y permite reintentar la consulta', () async {
      const failure = AreaCatalogFailureException(
        AreaCatalogFailure.connection,
      );
      final repository = _FakeAreaRepository(
        Result.error(failure),
        retryResult: Result.ok(const []),
      );
      final viewModel = AreaCatalogViewModel(GetAreas(repository));
      addTearDown(viewModel.dispose);

      await viewModel.loadAreas();

      expect(viewModel.state.status, AreaCatalogStatus.error);
      expect(viewModel.state.failure, same(failure));
      expect(viewModel.state.technicalError, isNull);

      await viewModel.loadAreas();

      expect(repository.callCount, 2);
      expect(viewModel.state.status, AreaCatalogStatus.empty);
    });

    test('distingue errores no tipados como inesperados', () async {
      final error = Exception('Error no previsto');
      final repository = _FakeAreaRepository(Result.error(error));
      final viewModel = AreaCatalogViewModel(GetAreas(repository));
      addTearDown(viewModel.dispose);

      await viewModel.loadAreas();

      expect(viewModel.state.status, AreaCatalogStatus.unexpectedFailure);
      expect(viewModel.state.failure, isNull);
      expect(viewModel.state.technicalError, same(error));
    });
  });
}

class _FakeAreaRepository implements AreaRepository {
  _FakeAreaRepository(this.result, {this.retryResult});

  final Result<List<Area>> result;
  final Result<List<Area>>? retryResult;
  int callCount = 0;

  @override
  Future<Result<List<Area>>> getAreas() async {
    callCount++;
    return callCount > 1 && retryResult != null ? retryResult! : result;
  }
}
