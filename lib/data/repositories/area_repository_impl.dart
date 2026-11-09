import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/data/datasources/area_remote_data_source.dart';
import 'package:internal_request_app/domain/errors/area_catalog_failures.dart';
import 'package:internal_request_app/domain/models/area.dart';
import 'package:internal_request_app/domain/repositories/area_repository.dart';

final class AreaRepositoryImpl implements AreaRepository {
  AreaRepositoryImpl(this._areaRemoteDataSource);

  final AreaRemoteDataSource _areaRemoteDataSource;

  @override
  Future<Result<List<Area>>> getAreas() async {
    final result = await _areaRemoteDataSource.getAreas();

    return switch (result) {
      Ok<List<Area>>() => Result.ok(result.value),
      Error<List<Area>>() => Result.error(_mapFailure(result.error)),
    };
  }


  //mapeo de excepciones tecnicas del datasourrce, a failures definidos en dominio
  AreaCatalogFailureException _mapFailure(Exception exception) {
    if (exception is! AreaRemoteDataSourceException) {
      return const AreaCatalogFailureException(AreaCatalogFailure.unknown);
    }

    final failure = switch (exception.failure) {
      AreaRemoteDataSourceFailure.timeout => AreaCatalogFailure.timeout,
      AreaRemoteDataSourceFailure.connection => AreaCatalogFailure.connection,
      AreaRemoteDataSourceFailure.notFound => AreaCatalogFailure.notFound,
      AreaRemoteDataSourceFailure.server => AreaCatalogFailure.server,
      AreaRemoteDataSourceFailure.http => AreaCatalogFailure.http,
      AreaRemoteDataSourceFailure.invalidResponse =>
        AreaCatalogFailure.invalidResponse,
      AreaRemoteDataSourceFailure.unknown => AreaCatalogFailure.unknown,
    };

    return AreaCatalogFailureException(failure);
  }
}
