import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/models/area.dart';

final class AreaRemoteDataSource {
  factory AreaRemoteDataSource({
    required http.Client client,
    required String apiBaseUrl,
    Duration timeout = const Duration(seconds: 15),
  }) => AreaRemoteDataSource._(client, apiBaseUrl, timeout);

  AreaRemoteDataSource._(this._client, this._apiBaseUrl, this.timeout);

  final http.Client _client;
  final String _apiBaseUrl;
  final Duration timeout;

  Future<Result<List<Area>>> getAreas() async {
    final uri = Uri.parse('$_apiBaseUrl/areas');

    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      return Result.error(
        const AreaRemoteDataSourceException(
          AreaRemoteDataSourceFailure.timeout,
          'La petición de áreas superó el tiempo límite.',
        ),
      );
    } on http.ClientException {
      return Result.error(
        const AreaRemoteDataSourceException(
          AreaRemoteDataSourceFailure.connection,
          'No fue posible conectar con el catálogo de áreas.',
        ),
      );
    } on Exception catch (exception) {
      return Result.error(
        AreaRemoteDataSourceException(
          AreaRemoteDataSourceFailure.unknown,
          'Ocurrió un error al consultar las áreas: $exception',
        ),
      );
    }

    if (response.statusCode != 200) {
      return Result.error(_httpFailure(response.statusCode));
    }

    late final dynamic data;
    try {
      data = jsonDecode(response.body);
    } on FormatException catch (exception) {
      return Result.error(
        AreaRemoteDataSourceException(
          AreaRemoteDataSourceFailure.invalidResponse,
          'La respuesta de áreas no contiene JSON válido: $exception',
        ),
      );
    }

    if (data is! List) {
      return Result.error(
        const AreaRemoteDataSourceException(
          AreaRemoteDataSourceFailure.invalidResponse,
          'La respuesta de áreas debe ser una lista.',
        ),
      );
    }

    try {
      final areas = data
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException(
                'Cada elemento de la respuesta debe ser un objeto JSON.',
              );
            }

            return Area.fromJson(item);
          })
          .toList(growable: false);

      return Result.ok(areas);
    } on FormatException catch (exception) {
      return Result.error(
        AreaRemoteDataSourceException(
          AreaRemoteDataSourceFailure.invalidResponse,
          'No fue posible interpretar uno o varios registros: $exception',
        ),
      );
    } on Exception catch (exception) {
      return Result.error(
        AreaRemoteDataSourceException(
          AreaRemoteDataSourceFailure.unknown,
          'Ocurrió un error al procesar las áreas: $exception',
        ),
      );
    }
  }

  AreaRemoteDataSourceException _httpFailure(int statusCode) {
    if (statusCode == 404) {
      return const AreaRemoteDataSourceException(
        AreaRemoteDataSourceFailure.notFound,
        'No se encontró el endpoint del catálogo de áreas.',
      );
    }

    if (statusCode >= 500) {
      return AreaRemoteDataSourceException(
        AreaRemoteDataSourceFailure.server,
        'Ocurrio un error de servidor con código $statusCode.',
      );
    }

    return AreaRemoteDataSourceException(
      AreaRemoteDataSourceFailure.http,
      'La petición del catálogo respondió con código $statusCode.',
    );
  }
}

enum AreaRemoteDataSourceFailure {
  timeout,
  connection,
  notFound,
  server,
  http,
  invalidResponse,
  unknown,
}

final class AreaRemoteDataSourceException implements Exception {
  const AreaRemoteDataSourceException(this.failure, this.message);

  final AreaRemoteDataSourceFailure failure;
  final String message;

  @override
  String toString() => message;
}
