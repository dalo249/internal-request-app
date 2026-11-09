import 'package:flutter/material.dart';
import 'package:internal_request_app/domain/errors/area_catalog_failures.dart';
import 'package:internal_request_app/domain/models/area.dart';
import 'package:internal_request_app/domain/models/service.dart';
import 'package:internal_request_app/presentation/viewmodels/area_catalog_view_model.dart';
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

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'El formulario está listo, pero la creación de solicitudes aún no está conectada.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AreaCatalogViewModel>().state;

    return switch (state.status) {
      AreaCatalogStatus.idle || AreaCatalogStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      AreaCatalogStatus.error => _buildError(state.failure),
      AreaCatalogStatus.unexpectedFailure => _buildUnexpectedError(),
      AreaCatalogStatus.empty => _buildEmpty(),
      AreaCatalogStatus.loaded => _buildCatalog(state.areas),
    };
  }

  Widget _buildCatalog(List<Area> areas) {
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
                      onTap: () {
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
                                onPressed: _submit,
                                child: const Text('Enviar solicitud'),
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
