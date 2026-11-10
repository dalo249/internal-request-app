import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/data/datasources/request_local_data_source.dart';
import 'package:internal_request_app/data/datasources/request_remote_data_source.dart';
import 'package:internal_request_app/data/datasources/user_profile_remote_datasource.dart';
import 'package:internal_request_app/domain/errors/create_request_exception.dart';
import 'package:internal_request_app/domain/errors/get_requests_exception.dart';
import 'package:internal_request_app/domain/models/request.dart';
import 'package:internal_request_app/domain/models/request_record.dart';
import 'package:internal_request_app/domain/models/requester_requests.dart';
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
  Future<Result<RequesterRequests>> getRequestsForRequester(
    String requesterId,
  ) async {
    final remoteResult = await _requestRemoteDataSource.getRequestsForRequester(
      requesterId,
    );

    switch (remoteResult) {
      case Ok<List<RequestRecord>>():
        try {
          await _requestLocalDataSource.cacheSyncedRequests(remoteResult.value);
          final records = await _requestLocalDataSource.getRequestsForRequester(
            requesterId,
          );
          return Result.ok(
            RequesterRequests(records: records, isFromCache: false),
          );
        } on Exception catch (_) {
          return Result.ok(
            RequesterRequests(
              records: remoteResult.value,
              isFromCache: false,
              notice: 'No se pudo actualizar la copia local.',
            ),
          );
        }
      case Error<List<RequestRecord>>():
        try {
          final cachedRecords = await _requestLocalDataSource
              .getRequestsForRequester(requesterId);
          if (cachedRecords.isNotEmpty) {
            return Result.ok(
              RequesterRequests(
                records: cachedRecords,
                isFromCache: true,
                notice: _requestCacheNotice(remoteResult.error),
              ),
            );
          }
        } on Exception catch (_) {
          return Result.error(
            const GetRequestsException(
              'No se pudieron cargar las solicitudes guardadas.',
            ),
          );
        }

        return Result.error(
          const GetRequestsException(
            'No se pudieron cargar las solicitudes. Inténtalo de nuevo.',
          ),
        );
    }
  }

  String _requestCacheNotice(Exception exception) {
    if (exception is FirebaseException) {
      return switch (exception.code) {
        'permission-denied' =>
          'Sin permiso para consultar. Mostrando datos guardados.',
        'unauthenticated' =>
          'Inicia sesión para actualizar. Mostrando datos guardados.',
        _ => 'No se pudo actualizar. Mostrando datos guardados.',
      };
    }

    return 'No se pudo actualizar. Mostrando datos guardados.';
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
