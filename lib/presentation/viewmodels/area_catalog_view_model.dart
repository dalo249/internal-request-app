import 'package:flutter/foundation.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/errors/area_catalog_failures.dart';
import 'package:internal_request_app/domain/models/area.dart';
import 'package:internal_request_app/domain/usecases/get_areas.dart';

enum AreaCatalogStatus {
  idle,
  loading,
  loaded,
  empty,
  error,
  unexpectedFailure,
}

class AreaCatalogState {
  const AreaCatalogState({
    this.status = AreaCatalogStatus.idle,
    this.areas = const [],
    this.failure,
    this.technicalError,
    this.stackTrace,
  });

  final AreaCatalogStatus status;
  final List<Area> areas;
  final AreaCatalogFailureException? failure;
  final Object? technicalError;
  final StackTrace? stackTrace;
}

final class AreaCatalogViewModel extends ChangeNotifier {
  AreaCatalogViewModel(this._getAreas);

  final GetAreas _getAreas;

  AreaCatalogState _state = const AreaCatalogState();
  bool _isDisposed = false;

  AreaCatalogState get state => _state;

  Future<void> loadAreas() async {
    if (_state.status == AreaCatalogStatus.loading) return;

    _emit(const AreaCatalogState(status: AreaCatalogStatus.loading));

    try {
      final result = await _getAreas();

      switch (result) {
        case Ok<List<Area>>():
          final areas = List<Area>.unmodifiable(result.value);
          _emit(
            AreaCatalogState(
              status: areas.isEmpty
                  ? AreaCatalogStatus.empty
                  : AreaCatalogStatus.loaded,
              areas: areas,
            ),
          );
        case Error<List<Area>>():
          final error = result.error;
          if (error is AreaCatalogFailureException) {
            _emit(
              AreaCatalogState(status: AreaCatalogStatus.error, failure: error),
            );
          } else {
            _emit(
              AreaCatalogState(
                status: AreaCatalogStatus.unexpectedFailure,
                technicalError: error,
              ),
            );
          }
      }
    } on Object catch (error, stackTrace) {
      _emit(
        AreaCatalogState(
          status: AreaCatalogStatus.unexpectedFailure,
          technicalError: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  void _emit(AreaCatalogState state) {
    _state = state;
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
