import 'package:flutter/material.dart';
import 'package:internal_request_app/domain/enums/request_status.dart';
import 'package:internal_request_app/domain/models/requester_requests.dart';
import 'package:internal_request_app/domain/models/request_record.dart';
import 'package:internal_request_app/presentation/viewmodels/auth_gate_view_model.dart';
import 'package:internal_request_app/presentation/viewmodels/my_requests_view_model.dart';
import 'package:provider/provider.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadRequests();
    });
  }

  Future<void> _loadRequests() async {
    final requesterId =
        context.read<AuthGateViewModel>().state.profile?.uid ?? '';
    await context.read<MyRequestsViewModel>().loadRequests(requesterId);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MyRequestsViewModel>().state;
    return switch (state.status) {
      MyRequestsStatus.idle || MyRequestsStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      MyRequestsStatus.error => _buildError(state.failure?.message),
      MyRequestsStatus.empty => _buildEmpty(state.data?.notice),
      MyRequestsStatus.loaded => _buildList(state.data!),
    };
  }

  Widget _buildError(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message ?? 'No se pudieron cargar las solicitudes.'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadRequests,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(String? notice) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (notice != null) ...[
            Text(notice, textAlign: TextAlign.center),
            const SizedBox(height: 12),
          ],
          const Text('Todavía no tienes solicitudes.'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loadRequests,
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(RequesterRequests data) {
    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (data.notice != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(data.notice!),
                ),
              ),
            ),
          ...data.records.map(_buildRequestCard),
        ],
      ),
    );
  }

  Widget _buildRequestCard(RequestRecord record) {
    final request = record.request;
    final isOverdue =
        request.limitDate != null &&
        request.limitDate!.isBefore(DateTime.now()) &&
        request.status != RequestStatus.closed &&
        request.status != RequestStatus.rejected;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Servicio ${request.serviceId}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (isOverdue)
                  const Chip(
                    label: Text('Vencida'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(request.description),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(_statusLabel(request.status)),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(_syncStatusLabel(record.syncStatus)),
                  visualDensity: VisualDensity.compact,
                ),
                if (request.priority != null)
                  Chip(
                    label: Text('Prioridad: ${request.priority!.value}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: request.progress.clamp(0, 100) / 100,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${request.progress}%'),
              ],
            ),
            if (request.limitDate != null) ...[
              const SizedBox(height: 8),
              Text('Fecha límite: ${_formatDate(request.limitDate!)}'),
            ],
            if (record.lastSyncError != null &&
                record.syncStatus != RequestSyncStatus.synced) ...[
              const SizedBox(height: 8),
              Text(
                record.lastSyncError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(RequestStatus status) => switch (status) {
    RequestStatus.requested => 'Solicitada',
    RequestStatus.approved => 'Autorizada',
    RequestStatus.inProgress => 'En proceso',
    RequestStatus.completed => 'Por validar',
    RequestStatus.closed => 'Cerrada',
    RequestStatus.rejected => 'Rechazada',
  };

  String _syncStatusLabel(RequestSyncStatus status) => switch (status) {
    RequestSyncStatus.pending => 'Pendiente de sincronizar',
    RequestSyncStatus.synced => 'Sincronizada',
    RequestSyncStatus.conflict => 'Requiere revisión',
  };

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
