import 'package:internal_request_app/core/utils/result.dart';
import 'package:internal_request_app/domain/enums/request_status.dart';
import 'package:internal_request_app/domain/errors/create_request_exception.dart';
import 'package:internal_request_app/domain/models/request.dart';
import 'package:internal_request_app/domain/models/request_record.dart';
import 'package:internal_request_app/domain/repositories/request_repository.dart';
import 'package:uuid/uuid.dart';

final class CreateRequest {
  CreateRequest(this._requestRepository, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final RequestRepository _requestRepository;
  final Uuid _uuid;

  Future<Result<RequestRecord>> call({
    required String requesterId,
    required String serviceId,
    required String description,
  }) async {
    final trimmedRequesterId = requesterId.trim();
    final trimmedServiceId = serviceId.trim();
    final trimmedDescription = description.trim();

    final validationError =
        _validateRequester(trimmedRequesterId) ??
        _validateService(trimmedServiceId) ??
        _validateDescription(trimmedDescription);

    if (validationError != null) {
      return Result.error(CreateRequestValidationException(validationError));
    }

    final request = Request(
      id: _uuid.v4(),
      serviceId: trimmedServiceId,
      requesterId: trimmedRequesterId,
      description: trimmedDescription,
      status: RequestStatus.requested,
      progress: 0,
    );

    return _requestRepository.createRequest(request);
  }


  //validaciones de formulario para crear una solicitud
  CreateRequestValidationError? _validateRequester(String requesterId) {
    return requesterId.isEmpty
        ? CreateRequestValidationError.requesterRequired
        : null;
  }

  CreateRequestValidationError? _validateService(String serviceId) {
    return serviceId.isEmpty
        ? CreateRequestValidationError.serviceRequired
        : null;
  }

  CreateRequestValidationError? _validateDescription(String description) {
    return description.isEmpty
        ? CreateRequestValidationError.descriptionRequired
        : null;
  }
}
