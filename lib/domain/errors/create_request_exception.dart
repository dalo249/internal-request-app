enum CreateRequestValidationError {
  requesterRequired,
  serviceRequired,
  descriptionRequired,
}

final class CreateRequestValidationException implements Exception {
  const CreateRequestValidationException(this.error);

  final CreateRequestValidationError error;

  @override
  String toString() => 'CreateRequestValidationException($error)';
}

final class RequestPersistenceException implements Exception {
  const RequestPersistenceException(this.cause);

  final Exception cause;

  @override
  String toString() => 'RequestPersistenceException($cause)';
}

enum RequestAssignmentFailure {
  noEligibleSupervisor,
  rejected,
  authentication,
  supervisorLookupDenied,
  permissionDenied,
  network,
  unknown,
}

final class RequestAssignmentException implements Exception {
  const RequestAssignmentException(this.failure, this.message);

  final RequestAssignmentFailure failure;
  final String message;

  @override
  String toString() => 'RequestAssignmentException($failure: $message)';
}
