import 'package:flutter/foundation.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/errors/create_request_exception.dart';
import 'package:internal_request_app/domain/models/request_record.dart';
import 'package:internal_request_app/domain/usecases/create_request.dart';

enum CreateRequestStatus {
  idle,
  submitting,
  success,
  validationFailure,
  persistenceFailure,
  assignmentFailure,
  unexpectedFailure,
}

class CreateRequestState {
  const CreateRequestState({
    this.status = CreateRequestStatus.idle,
    this.record,
    this.validationError,
    this.persistenceError,
    this.assignmentError,
    this.technicalError,
  });

  final CreateRequestStatus status;
  final RequestRecord? record;
  final CreateRequestValidationError? validationError;
  final RequestPersistenceException? persistenceError;
  final RequestAssignmentException? assignmentError;
  final Object? technicalError;
}

final class CreateRequestViewModel extends ChangeNotifier {
  CreateRequestViewModel(this._createRequest);

  final CreateRequest _createRequest;

  CreateRequestState _state = const CreateRequestState();
  bool _isDisposed = false;

  CreateRequestState get state => _state;

  Future<void> createRequest({
    required String requesterId,
    required String serviceId,
    required String description,
  }) async {
    if (_state.status == CreateRequestStatus.submitting) return;

    _emit(const CreateRequestState(status: CreateRequestStatus.submitting));

    try {
      final result = await _createRequest(
        requesterId: requesterId,
        serviceId: serviceId,
        description: description,
      );

      switch (result) {
        case Ok<RequestRecord>():
          _emit(
            CreateRequestState(
              status: CreateRequestStatus.success,
              record: result.value,
            ),
          );
        case Error<RequestRecord>():
          final error = result.error;
          if (error is CreateRequestValidationException) {
            _emit(
              CreateRequestState(
                status: CreateRequestStatus.validationFailure,
                validationError: error.error,
              ),
            );
          } else if (error is RequestPersistenceException) {
            _emit(
              CreateRequestState(
                status: CreateRequestStatus.persistenceFailure,
                persistenceError: error,
              ),
            );
          } else if (error is RequestAssignmentException) {
            _emit(
              CreateRequestState(
                status: CreateRequestStatus.assignmentFailure,
                assignmentError: error,
              ),
            );
          } else {
            _emit(
              CreateRequestState(
                status: CreateRequestStatus.unexpectedFailure,
                technicalError: error,
              ),
            );
          }
      }
    } on Object catch (error) {
      _emit(
        CreateRequestState(
          status: CreateRequestStatus.unexpectedFailure,
          technicalError: error,
        ),
      );
    }
  }

  void reset() {
    _emit(const CreateRequestState());
  }

  void _emit(CreateRequestState state) {
    _state = state;
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
