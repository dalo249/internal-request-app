import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/data/datasources/request_local_data_source.dart';
import 'package:internal_request_app/data/datasources/request_remote_data_source.dart';
import 'package:internal_request_app/data/datasources/user_profile_remote_datasource.dart';
import 'package:internal_request_app/domain/errors/create_request_exception.dart';
import 'package:internal_request_app/domain/models/request.dart';
import 'package:internal_request_app/domain/models/request_record.dart';
import 'package:internal_request_app/domain/models/user_profile.dart';
import 'package:internal_request_app/domain/repositories/request_repository.dart';

final class RequestRepositoryImpl implements RequestRepository {
  RequestRepositoryImpl(
    this._requestLocalDataSource,
    this._requestRemoteDataSource,
    this._userProfileRemoteDataSource,
  );

  final RequestLocalDataSource _requestLocalDataSource;
  final RequestRemoteDataSource _requestRemoteDataSource;
  final UserProfileRemoteDataSource _userProfileRemoteDataSource;

  @override
  Future<Result<RequestRecord>> createRequest(Request request) async {
    final supervisorsResult = await _userProfileRemoteDataSource
        .getSupervisors();
    final List<UserProfile> supervisors;
    switch (supervisorsResult) {
      case Ok<List<UserProfile>>():
        supervisors = supervisorsResult.value;
      case Error<List<UserProfile>>():
        return Result.error(
          _mapSupervisorLookupFailure(supervisorsResult.error),
        );
    }

    final eligibleSupervisors = supervisors.where(
      (supervisor) => supervisor.uid != request.requesterId,
    );
    if (eligibleSupervisors.isEmpty) {
      return Result.error(
        const RequestAssignmentException(
          RequestAssignmentFailure.noEligibleSupervisor,
          'No hay otro supervisor disponible.',
        ),
      );
    }
    final approverId = eligibleSupervisors.first.uid;

    try {
      await _requestLocalDataSource.saveRequest(request);
    } on Exception catch (error) {
      return Result.error(RequestPersistenceException(error));
    }

    final remoteResult = await _requestRemoteDataSource.createRequest(
      request,
      approverId: approverId,
    );
    switch (remoteResult) {
      case Ok<void>():
        try {
          final syncedRecord = await _requestLocalDataSource
              .updateRequestAfterSync(request.id, approverId: approverId);
          return Result.ok(syncedRecord);
        } on Exception catch (error) {
          return Result.error(RequestPersistenceException(error));
        }
      case Error<void>():
        final error = remoteResult.error;
        if (_isRetryableRemoteFailure(error)) {
          try {
            final pendingRecord = await _requestLocalDataSource
                .recordPendingSyncError(request.id, error.toString());
            return Result.ok(pendingRecord);
          } on Exception catch (localError) {
            return Result.error(RequestPersistenceException(localError));
          }
        }

        try {
          await _requestLocalDataSource.markRequestConflict(
            request.id,
            error.toString(),
          );
        } on Exception catch (localError) {
          return Result.error(RequestPersistenceException(localError));
        }
        return Result.error(_mapAssignmentFailure(error));
    }
  }

  @override
  Future<List<RequestRecord>> getRequestsForRequester(String requesterId) {
    return _requestLocalDataSource.getRequestsForRequester(requesterId);
  }

  //mapeo de excepciones
  RequestAssignmentException _mapAssignmentFailure(Exception exception) {
    if (exception is FirebaseException) {
      final (failure, message) = switch (exception.code) {
        'unauthenticated' => (
          RequestAssignmentFailure.authentication,
          'Inicia sesión e inténtalo de nuevo.',
        ),
        'permission-denied' => (
          RequestAssignmentFailure.permissionDenied,
          'No tienes permiso para crear la solicitud.',
        ),
        'invalid-argument' || 'failed-precondition' => (
          RequestAssignmentFailure.rejected,
          'Los datos de la solicitud no son válidos.',
        ),
        'unavailable' || 'deadline-exceeded' || 'aborted' => (
          RequestAssignmentFailure.network,
          'Problema de conexión. Inténtalo de nuevo.',
        ),
        _ => (
          RequestAssignmentFailure.unknown,
          'No se pudo crear la solicitud.',
        ),
      };

      return RequestAssignmentException(failure, message);
    }

    return RequestAssignmentException(
      RequestAssignmentFailure.unknown,
      'No se pudo crear la solicitud.',
    );
  }

  RequestAssignmentException _mapSupervisorLookupFailure(Exception exception) {
    if (exception is FirebaseException) {
      if (exception.code == 'permission-denied') {
        return const RequestAssignmentException(
          RequestAssignmentFailure.supervisorLookupDenied,
          'No se pudo consultar la lista de supervisores.',
        );
      }

      final mappedException = _mapAssignmentFailure(exception);
      return RequestAssignmentException(
        mappedException.failure,
        switch (mappedException.failure) {
          RequestAssignmentFailure.authentication =>
            'Inicia sesión e inténtalo de nuevo.',
          RequestAssignmentFailure.supervisorLookupDenied =>
            'No se pudo consultar la lista de supervisores.',
          RequestAssignmentFailure.permissionDenied =>
            'No tienes permiso para consultar supervisores.',
          RequestAssignmentFailure.network =>
            'Problema de conexión. Inténtalo de nuevo.',
          RequestAssignmentFailure.rejected =>
            'No se pudo consultar la lista de supervisores.',
          RequestAssignmentFailure.noEligibleSupervisor =>
            'No hay otro supervisor disponible.',
          RequestAssignmentFailure.unknown =>
            'No se pudieron consultar los supervisores.',
        },
      );
    }

    return RequestAssignmentException(
      RequestAssignmentFailure.unknown,
      'No se pudieron consultar los supervisores.',
    );
  }

  bool _isRetryableRemoteFailure(Exception exception) {
    if (exception is! FirebaseException) return true;

    return switch (exception.code) {
      'permission-denied' ||
      'unauthenticated' ||
      'invalid-argument' ||
      'failed-precondition' => false,
      _ => true,
    };
  }
}
