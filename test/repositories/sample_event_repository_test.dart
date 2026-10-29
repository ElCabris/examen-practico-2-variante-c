import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_track_shell/database/app_database.dart';
import 'package:sample_track_shell/models/sample_event.dart';
import 'package:sample_track_shell/models/sample_status.dart';
import 'package:sample_track_shell/repositories/sample_event_repository.dart';
import 'package:sample_track_shell/services/sample_event_remote_service.dart';

import '../support/fakes.dart';

void main() {
  late AppDatabase database;
  late FakeRemoteService remote;
  late SampleEventRepository repository;
  final base = DateTime(2026, 10, 28, 8);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    remote = FakeRemoteService();
    repository = SampleEventRepository(database: database, remote: remote);
  });

  tearDown(() => database.close());

  test('la lectura remota exitosa actualiza la cache de Drift', () async {
    remote.stored.addAll([
      event('M-1001', 'RECEIVED', base),
      event('M-1002', 'RECEIVED', base.add(const Duration(minutes: 1))),
    ]);

    final result = await repository.getAllEvents();

    expect(result.source, EventSource.remote);
    expect(result.events, hasLength(2));
    expect(await database.getAllEvents(), hasLength(2));
  });

  test('si Firestore falla se usan los ultimos eventos de Drift', () async {
    remote.stored.add(event('M-1001', 'RECEIVED', base));
    await repository.getAllEvents();

    remote.failReads = true;
    final result = await repository.getEventsForSample('M-1001');

    expect(result.isFromCache, isTrue);
    expect(result.remoteError, isA<RemoteDataException>());
    expect(result.events.single.type, 'RECEIVED');
  });

  test('cada muestra recupera solo sus eventos', () async {
    remote.stored.addAll([
      event('M-1001', 'RECEIVED', base),
      event('M-1002', 'RECEIVED', base),
      event('M-1001', 'PREPARED', base.add(const Duration(minutes: 1))),
    ]);
    await repository.getAllEvents();

    expect(
      (await database.getEventsForSample('M-1001')).map((e) => e.type),
      ['RECEIVED', 'PREPARED'],
    );
    final remoteResult = await repository.getEventsForSample('M-1002');
    expect(remoteResult.events.map((e) => e.sampleId), ['M-1002']);
  });

  test('registrar eventos conserva el historial completo', () async {
    for (final (i, status) in SampleStatus.values.indexed) {
      await repository.registerEvent(
        SampleEvent.create(
          sampleId: 'M-1005',
          status: status,
          createdAt: base.add(Duration(minutes: i)),
        ),
      );
    }

    final local = await database.getEventsForSample('M-1005');
    expect(local.map((e) => e.type),
        SampleStatus.values.map((s) => s.code).toList());
    expect(remote.stored, hasLength(5));
  });

  test('no se permite saltar estados ni persistir la transicion invalida',
      () async {
    await repository.registerEvent(
      SampleEvent.create(
        sampleId: 'M-1001',
        status: SampleStatus.received,
        createdAt: base,
      ),
    );

    await expectLater(
      repository.registerEvent(
        SampleEvent.create(
          sampleId: 'M-1001',
          status: SampleStatus.inAnalysis,
          createdAt: base.add(const Duration(minutes: 1)),
        ),
      ),
      throwsA(isA<InvalidTransitionException>()),
    );
    expect(remote.stored, hasLength(1));
    expect(await database.getEventsForSample('M-1001'), hasLength(1));
  });

  test('si la escritura remota falla el evento no se guarda localmente',
      () async {
    remote.failWrites = true;

    await expectLater(
      repository.registerEvent(
        SampleEvent.create(sampleId: 'M-1002', status: SampleStatus.received),
      ),
      throwsA(isA<RemoteDataException>()),
    );
    expect(await database.getAllEvents(), isEmpty);
  });

  test('las fechas conservan los milisegundos en Drift', () async {
    final createdAt = DateTime(2026, 10, 28, 8, 0, 0, 123);
    await database.upsertEvent(event('M-1003', 'RECEIVED', createdAt));

    final stored = (await database.getAllEvents()).single;
    expect(stored.createdAt.isAtSameMomentAs(createdAt), isTrue);
  });
}
