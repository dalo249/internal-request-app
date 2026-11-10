import 'package:flutter/foundation.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/errors/get_requests_exception.dart';
import 'package:internal_request_app/domain/models/requester_requests.dart';
import 'package:internal_request_app/domain/usecases/get_requests_for_requester.dart';

enum MyRequestsStatus { idle, loading, loaded, empty, error }

final class MyRequestsState {
  const MyRequestsState({
    this.status = MyRequestsStatus.idle,
    this.data,
    this.failure,
    this.technicalError,
  });

  final MyRequestsStatus status;
  final RequesterRequests? data;
  final GetRequestsException? failure;
  final Object? technicalError;
}

final class MyRequestsViewModel extends ChangeNotifier {
  MyRequestsViewModel(this._getRequestsForRequester);

  final GetRequestsForRequester _getRequestsForRequester;

  MyRequestsState _state = const MyRequestsState();
  bool _isDisposed = false;

  MyRequestsState get state => _state;

  Future<void> loadRequests(String requesterId) async {
    if (_state.status == MyRequestsStatus.loading) return;
    _emit(const MyRequestsState(status: MyRequestsStatus.loading));

    try {
      final result = await _getRequestsForRequester(requesterId);
      switch (result) {
        case Ok<RequesterRequests>():
          final data = result.value;
          _emit(
            MyRequestsState(
              status: data.records.isEmpty
                  ? MyRequestsStatus.empty
                  : MyRequestsStatus.loaded,
              data: data,
            ),
          );
        case Error<RequesterRequests>():
          final error = result.error;
          _emit(
            MyRequestsState(
              status: MyRequestsStatus.error,
              failure: error is GetRequestsException
                  ? error
                  : const GetRequestsException(
                      'No se pudieron cargar las solicitudes.',
                    ),
            ),
          );
      }
    } on Object catch (error) {
      _emit(
        MyRequestsState(
          status: MyRequestsStatus.error,
          failure: const GetRequestsException(
            'No se pudieron cargar las solicitudes.',
          ),
          technicalError: error,
        ),
      );
    }
  }

  void _emit(MyRequestsState state) {
    _state = state;
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
