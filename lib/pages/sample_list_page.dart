import 'package:flutter/material.dart';

import '../data/sample_seed.dart';
import '../models/sample.dart';
import '../models/sample_dashboard.dart';
import '../models/sample_status.dart';
import '../repositories/sample_event_repository.dart';
import '../utils/date_format.dart';
import '../widgets/data_source_banner.dart';
import '../widgets/sample_card.dart';
import 'sample_detail_page.dart';

class SampleListPage extends StatefulWidget {
  const SampleListPage({super.key, required this.repository});

  final SampleEventRepository repository;

  @override
  State<SampleListPage> createState() => _SampleListPageState();
}

class _SampleListPageState extends State<SampleListPage> {
  SampleEventsResult? _result;
  Object? _error;
  SampleFilter _filter = const SampleFilter();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await widget.repository.getAllEvents();
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _openDetail(Sample sample) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SampleDetailPage(
          sample: sample,
          repository: widget.repository,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.biotech_outlined),
            SizedBox(width: 10),
            Text('SampleTrack'),
          ],
        ),
      ),
      body: SafeArea(
        child: result == null
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : Text('No se pudieron cargar los eventos: $_error'),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: _buildDashboard(result),
              ),
      ),
    );
  }

  Widget _buildDashboard(SampleEventsResult result) {
    final dashboard = SampleDashboard(
      samples: sampleSeed,
      events: result.events,
    );
    final counts = dashboard.countsByStatus();
    final attention = dashboard.requiringAttention();
    final visible = dashboard.visible(_filter);
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (result.isFromCache) const LocalDataNotice(),
        Text('Resumen por estado', style: titleStyle),
        Wrap(
          spacing: 8,
          children: [
            for (final status in statusOptions)
              Chip(
                shape: const RoundedRectangleBorder(),
                label: Text(
                  '${SampleStatus.labelOf(status)}: ${counts[status]}',
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Requieren atención', style: titleStyle),
        if (attention.isEmpty)
          const Text('Todas las muestras están archivadas.'),
        for (final overview in attention)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${overview.sample.id} · ${overview.sample.priority}'),
            subtitle: Text(
              overview.lastUpdate == null
                  ? '${SampleStatus.labelOf(overview.status)} · '
                      'Sin actualizaciones'
                  : '${SampleStatus.labelOf(overview.status)} · Actualizada '
                      '${formatDateTime(overview.lastUpdate!)}',
            ),
            onTap: () => _openDetail(overview.sample),
          ),
        const SizedBox(height: 16),
        Text('Muestras', style: titleStyle),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _filter.status,
                decoration: const InputDecoration(labelText: 'Estado actual'),
                items: [
                  for (final label in [
                    SampleFilter.allStatuses,
                    ...statusOptions.map(SampleStatus.labelOf),
                  ])
                    DropdownMenuItem(value: label, child: Text(label)),
                ],
                onChanged: (value) => setState(
                  () => _filter = _filter.copyWith(status: value),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _filter.priority,
                decoration: const InputDecoration(labelText: 'Prioridad'),
                items: [
                  for (final priority in [
                    SampleFilter.allPriorities,
                    ...samplePriorities,
                  ])
                    DropdownMenuItem(value: priority, child: Text(priority)),
                ],
                onChanged: (value) => setState(
                  () => _filter = _filter.copyWith(priority: value),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const SizedBox(height: 8),
        Text('Mostrando ${visible.length} de ${dashboard.total} muestras'),
        const SizedBox(height: 12),
        for (final overview in visible) ...[
          SampleCard(
            sample: overview.sample,
            status: SampleStatus.labelOf(overview.status),
            onTap: () => _openDetail(overview.sample),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
