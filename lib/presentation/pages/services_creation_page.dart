import 'package:flutter/material.dart';
import 'package:internal_request_app/domain/errors/area_catalog_failures.dart';
import 'package:internal_request_app/domain/errors/create_request_exception.dart';
import 'package:internal_request_app/domain/models/area.dart';
import 'package:internal_request_app/domain/models/request_record.dart';
import 'package:internal_request_app/domain/models/service.dart';
import 'package:internal_request_app/presentation/viewmodels/area_catalog_view_model.dart';
import 'package:internal_request_app/presentation/viewmodels/auth_gate_view_model.dart';
import 'package:internal_request_app/presentation/viewmodels/create_request_view_model.dart';
import 'package:provider/provider.dart';

class ServicesCreationPage extends StatefulWidget {
  const ServicesCreationPage({super.key});

  @override
  State<ServicesCreationPage> createState() => _ServicesCreationPageState();
}

class _ServicesCreationPageState extends State<ServicesCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  Service? _selectedService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAreas();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadAreas() {
    _clearSelection();
    context.read<AreaCatalogViewModel>().loadAreas();
  }

  void _clearSelection() {
    setState(() {
      _selectedService = null;
      _descriptionController.clear();
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    final profile = context.read<AuthGateViewModel>().state.profile;
    if (profile == null) {
      _showMessage('No se pudo identificar al usuario autenticado.');
      return;
    }

    final service = _selectedService;
    if (service == null) return;

    final viewModel = context.read<CreateRequestViewModel>();
    await viewModel.createRequest(
      requesterId: profile.uid,
      serviceId: service.id,
      description: _descriptionController.text,
    );

    if (!mounted) return;

    final state = viewModel.state;
    switch (state.status) {
      case CreateRequestStatus.success:
        final record = state.record!;
        final message = switch (record.syncStatus) {
          RequestSyncStatus.synced =>
            'Solicitud guardada y sincronizada correctamente.',
          RequestSyncStatus.pending =>
            'Solicitud guardada localmente. Está pendiente de sincronización.',
          RequestSyncStatus.conflict => 'La solicitud requiere revisión.',
        };
        _showMessage(message);
        viewModel.reset();
        _clearSelection();
      case CreateRequestStatus.validationFailure:
        _showMessage(_validationMessage(state.validationError));
      case CreateRequestStatus.persistenceFailure:
        _showMessage('No se pudo guardar la solicitud.');
      case CreateRequestStatus.assignmentFailure:
        _showMessage(_assignmentMessage(state.assignmentError));
      case CreateRequestStatus.unexpectedFailure:
        _showMessage('No se pudo crear la solicitud. Inténtalo de nuevo.');
      case CreateRequestStatus.idle:
      case CreateRequestStatus.submitting:
        break;
    }
  }

  String _validationMessage(CreateRequestValidationError? error) {
    return switch (error) {
      CreateRequestValidationError.requesterRequired =>
        'Inicia sesión para continuar.',
      CreateRequestValidationError.serviceRequired => 'Selecciona un servicio.',
      CreateRequestValidationError.descriptionRequired =>
        'Ingresa una descripción para la solicitud.',
      null => 'Revisa los datos de la solicitud.',
    };
  }

  String _assignmentMessage(RequestAssignmentException? error) {
    return switch (error?.failure) {
      RequestAssignmentFailure.noEligibleSupervisor =>
        'No hay otro supervisor disponible.',
      RequestAssignmentFailure.authentication =>
        'Inicia sesión e inténtalo de nuevo.',
      RequestAssignmentFailure.supervisorLookupDenied =>
        'No se pudo consultar la lista de supervisores.',
      RequestAssignmentFailure.permissionDenied =>
        'No se pudo crear la solicitud. Revisa los permisos de Firestore.',
      RequestAssignmentFailure.network =>
        'Problema de conexión. Inténtalo de nuevo.',
      RequestAssignmentFailure.rejected =>
        'Los datos de la solicitud no son válidos.',
      RequestAssignmentFailure.unknown ||
      null => 'No se pudo crear la solicitud. Inténtalo de nuevo.',
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AreaCatalogViewModel>().state;
    final isSubmitting =
        context.watch<CreateRequestViewModel>().state.status ==
        CreateRequestStatus.submitting;

    return switch (state.status) {
      AreaCatalogStatus.idle || AreaCatalogStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      AreaCatalogStatus.error => _buildError(state.failure),
      AreaCatalogStatus.unexpectedFailure => _buildUnexpectedError(),
      AreaCatalogStatus.empty => _buildEmpty(),
      AreaCatalogStatus.loaded => _buildCatalog(
        state.areas,
        isSubmitting: isSubmitting,
      ),
    };
  }

  Widget _buildCatalog(List<Area> areas, {required bool isSubmitting}) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Servicios disponibles',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Selecciona el servicio para realizar la solicitud.'),
          const SizedBox(height: 12),
          ...areas.map(
            (area) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    area.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (area.services.isEmpty)
                  const Text('No hay servicios disponibles.'),
                ...area.services.map((service) {
                  final isSelected = _selectedService == service;

                  return Card(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: isSubmitting
                          ? null
                          : () {
                              if (isSelected) return;
                              setState(() {
                                _selectedService = service;
                                _descriptionController.clear();
                              });
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    service.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${service.estimatedDays} '
                                    '${service.estimatedDays == 1 ? 'día' : 'días'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(service.description),
                            if (isSelected) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _descriptionController,
                                enabled: !isSubmitting,
                                decoration: const InputDecoration(
                                  labelText: 'Descripción de la solicitud',
                                  hintText:
                                      'Describe brevemente lo que necesitas',
                                  border: OutlineInputBorder(),
                                  alignLabelWithHint: true,
                                ),
                                minLines: 3,
                                maxLines: 5,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingresa una descripción.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: isSubmitting ? null : _submit,
                                child: isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Enviar solicitud'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AreaCatalogFailureException? failure) {
    final message = switch (failure?.failure) {
      AreaCatalogFailure.timeout =>
        'El catálogo tardó demasiado en responder. Intenta de nuevo.',
      AreaCatalogFailure.connection =>
        'No fue posible conectar con el catálogo. Revisa tu conexión.',
      AreaCatalogFailure.notFound => 'No se encontró el catálogo solicitado.',
      AreaCatalogFailure.server =>
        'El servidor del catálogo no está disponible. Intenta más tarde.',
      AreaCatalogFailure.http =>
        'La solicitud al catálogo falló en la peticion. Intenta de nuevo.',
      AreaCatalogFailure.invalidResponse =>
        'El catálogo devolvió información con un formato inválido.',
      AreaCatalogFailure.unknown ||
      null => 'No fue posible cargar el catálogo.',
    };

    return _messageState(
      message,
      actionLabel: 'Reintentar',
      onAction: _loadAreas,
    );
  }

  Widget _buildUnexpectedError() {
    return _messageState(
      'Ocurrió un error inesperado al cargar los servicios.',
      actionLabel: 'Reintentar',
      onAction: _loadAreas,
    );
  }

  Widget _buildEmpty() {
    return _messageState('No hay áreas o servicios disponibles.');
  }

  Widget _messageState(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
