import 'package:flutter/material.dart';

import '../models/sample.dart';
import '../models/sample_event.dart';
import '../models/sample_history.dart';
import '../models/sample_status.dart';
import '../repositories/sample_event_repository.dart';
import '../utils/date_format.dart';
import '../widgets/data_source_banner.dart';

class SampleDetailPage extends StatefulWidget {
  const SampleDetailPage({
    super.key,
    required this.sample,
    required this.repository,
  });

  final Sample sample;
  final SampleEventRepository repository;

  @override
  State<SampleDetailPage> createState() => _SampleDetailPageState();
}

class _SampleDetailPageState extends State<SampleDetailPage> {
  SampleEventsResult? _result;
  Object? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result =
          await widget.repository.getEventsForSample(widget.sample.id);
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _register(SampleStatus status) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.registerEvent(
        SampleEvent.create(sampleId: widget.sample.id, status: status),
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Evento ${status.code} registrado.')),
      );
    } on InvalidTransitionException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo registrar ${status.code} en Firestore: $error. '
            'El evento no fue guardado.',
          ),
        ),
      );
    }
    await _load();
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text(widget.sample.id)),
      body: result == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Text('No se pudo cargar el historial: $_error'),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: _buildContent(result),
            ),
    );
  }

  Widget _buildContent(SampleEventsResult result) {
    final history = SampleHistory(result.events);
    final next = history.nextStatus;

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (result.isFromCache) const LocalDataNotice(),
        _SampleHeader(
          sample: widget.sample,
          status: SampleStatus.labelOf(history.status),
        ),
        const SizedBox(height: 24),
        Text(
          'Historial de procesamiento',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 14),
        if (history.isEmpty) const _EmptyHistory(),
        for (final event in history.events)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(SampleStatus.labelOf(event.status)),
            subtitle: Text(
              '${event.type} · ${formatDateTime(event.createdAt)}',
            ),
          ),
        const SizedBox(height: 18),
        if (next == null)
          const Text('La muestra está archivada; no hay más eventos.')
        else
          FilledButton.icon(
            onPressed: _saving ? null : () => _register(next),
            icon: const Icon(Icons.add),
            label: Text('Registrar evento: ${next.label}'),
          ),
      ],
    );
  }
}

class _SampleHeader extends StatelessWidget {
  const _SampleHeader({required this.sample, required this.status});

  final Sample sample;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.science_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sample.id,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Chip(label: Text(status)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _InfoField(label: 'Tipo', value: sample.type),
                _InfoField(label: 'Origen', value: sample.origin),
                _InfoField(label: 'Prioridad', value: sample.priority),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'Esta muestra aun no tiene eventos de procesamiento.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
