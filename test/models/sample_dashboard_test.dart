import 'package:flutter_test/flutter_test.dart';
import 'package:sample_track_shell/data/sample_seed.dart';
import 'package:sample_track_shell/models/sample_dashboard.dart';
import 'package:sample_track_shell/models/sample_history.dart';
import 'package:sample_track_shell/models/sample_status.dart';

import '../support/fakes.dart';

void main() {
  final base = DateTime(2026, 10, 28, 8);
  DateTime at(int minutes) => base.add(Duration(minutes: minutes));

  group('SampleHistory', () {
    test('sin eventos el estado es null y el siguiente es RECEIVED', () {
      final history = SampleHistory(const []);
      expect(history.status, isNull);
      expect(SampleStatus.labelOf(history.status), 'Sin eventos');
      expect(history.nextStatus, SampleStatus.received);
    });

    test('el estado sale del evento mas reciente aunque llegue desordenado',
        () {
      final history = SampleHistory([
        event('M-1', 'IN_ANALYSIS', at(20)),
        event('M-1', 'RECEIVED', at(0)),
        event('M-1', 'PREPARED', at(10)),
      ]);
      expect(history.events.map((e) => e.type),
          ['RECEIVED', 'PREPARED', 'IN_ANALYSIS']);
      expect(history.status, SampleStatus.inAnalysis);
      expect(history.lastUpdate, at(20));
      expect(history.nextStatus, SampleStatus.validated);
    });

    test('despues de ARCHIVED no hay siguiente estado', () {
      expect(SampleStatus.nextAfter(SampleStatus.archived), isNull);
    });
  });

  group('SampleDashboard (variante C)', () {
    // M-1001 Alta, M-1002 Normal, M-1003 Alta, M-1004 Normal, M-1005 Urgente
    final dashboard = SampleDashboard(
      samples: sampleSeed,
      events: [
        event('M-1001', 'RECEIVED', at(0)),
        event('M-1001', 'PREPARED', at(30)),
        event('M-1003', 'RECEIVED', at(5)),
        event('M-1004', 'RECEIVED', at(1)),
        event('M-1004', 'PREPARED', at(2)),
        event('M-1004', 'IN_ANALYSIS', at(3)),
        event('M-1004', 'VALIDATED', at(4)),
        event('M-1004', 'ARCHIVED', at(6)),
        event('M-1005', 'RECEIVED', at(40)),
      ],
    );

    List<String> visibleIds(SampleFilter filter) =>
        dashboard.visible(filter).map((o) => o.sample.id).toList();

    test('sin filtros se ven todas, ordenadas por prioridad y fecha', () {
      expect(visibleIds(const SampleFilter()), [
        'M-1005', // Urgente
        'M-1003', // Alta, actualizada en el minuto 5
        'M-1001', // Alta, actualizada en el minuto 30
        'M-1002', // Normal, sin eventos
        'M-1004', // Normal, actualizada en el minuto 6
      ]);
    });

    test('filtros combinables por estado y prioridad', () {
      expect(visibleIds(const SampleFilter(priority: 'Alta')),
          ['M-1003', 'M-1001']);
      expect(
        visibleIds(const SampleFilter(priority: 'Alta', status: 'Recibida')),
        ['M-1003'],
      );
      expect(visibleIds(const SampleFilter(status: 'Sin eventos')), ['M-1002']);
      expect(
        visibleIds(const SampleFilter(status: 'Archivada', priority: 'Alta')),
        isEmpty,
      );
    });

    test('resumen con la cantidad de muestras por estado', () {
      final counts = dashboard.countsByStatus();
      expect(counts, {
        null: 1,
        SampleStatus.received: 2,
        SampleStatus.prepared: 1,
        SampleStatus.inAnalysis: 0,
        SampleStatus.validated: 0,
        SampleStatus.archived: 1,
      });
      expect(counts.values.reduce((a, b) => a + b), dashboard.total);
    });

    test('requieren atencion: sin archivadas, por prioridad y mas antigua', () {
      final attention = dashboard.requiringAttention();
      expect(attention.map((o) => o.sample.id), [
        'M-1005', // Urgente
        'M-1003', // Alta, actualizada en el minuto 5
        'M-1001', // Alta, actualizada en el minuto 30
        'M-1002', // Normal, sin eventos
      ]);
    });
  });
}
