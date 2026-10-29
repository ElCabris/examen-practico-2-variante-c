import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/sample_event.dart';

part 'app_database.g.dart';

@DataClassName('SampleEventRow')
@TableIndex(name: 'idx_sample_events_sample_id', columns: {#sampleId})
class SampleEvents extends Table {
  TextColumn get id => text()();
  TextColumn get sampleId => text()();
  TextColumn get type => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [SampleEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'sampletrack'));

  @override
  int get schemaVersion => 1;

  Future<void> upsertEvent(SampleEvent event) =>
      into(sampleEvents).insertOnConflictUpdate(_toCompanion(event));

  Future<void> upsertEvents(Iterable<SampleEvent> events) => batch(
        (batch) => batch.insertAllOnConflictUpdate(
          sampleEvents,
          events.map(_toCompanion).toList(),
        ),
      );

  Future<List<SampleEvent>> getAllEvents() async {
    final query = select(sampleEvents)
      ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]);
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  Future<List<SampleEvent>> getEventsForSample(String sampleId) async {
    final query = select(sampleEvents)
      ..where((table) => table.sampleId.equals(sampleId))
      ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]);
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  static SampleEventsCompanion _toCompanion(SampleEvent event) =>
      SampleEventsCompanion.insert(
        id: event.id,
        sampleId: event.sampleId,
        type: event.type,
        createdAt: event.createdAt,
      );

  static SampleEvent _toModel(SampleEventRow row) => SampleEvent(
        id: row.id,
        sampleId: row.sampleId,
        type: row.type,
        createdAt: row.createdAt,
      );
}
