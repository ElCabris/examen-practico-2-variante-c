import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_track_shell/database/app_database.dart';
import 'package:sample_track_shell/main.dart';
import 'package:sample_track_shell/repositories/sample_event_repository.dart';

import 'support/fakes.dart';

void main() {
  late AppDatabase database;
  late FakeRemoteService remote;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    remote = FakeRemoteService();
  });

  tearDown(() => database.close());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      SampleTrackApp(
        repository: SampleEventRepository(database: database, remote: remote),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('SampleTrack muestra el catalogo inicial', (tester) async {
    await pumpApp(tester);

    expect(find.text('SampleTrack'), findsOneWidget);
    expect(find.text('M-1001'), findsOneWidget);
    expect(find.text('M-1005'), findsOneWidget);
  });

  testWidgets('el tablero muestra resumen, atencion y contador',
      (tester) async {
    remote.stored.add(event('M-1005', 'RECEIVED', DateTime(2026, 10, 28, 8)));
    await pumpApp(tester);

    expect(find.text('Resumen por estado'), findsOneWidget);
    expect(find.text('Requieren atención'), findsOneWidget);
    expect(find.text('Mostrando 5 de 5 muestras'), findsOneWidget);
    expect(find.text('Mostrando datos locales'), findsNothing);

    final dropdowns = find.byType(DropdownButtonFormField<String>);

    await tester.tap(dropdowns.last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Urgente').last);
    await tester.pumpAndSettle();
    expect(find.text('Mostrando 1 de 5 muestras'), findsOneWidget);

    await tester.tap(dropdowns.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sin eventos').last);
    await tester.pumpAndSettle();
    expect(find.text('Mostrando 0 de 5 muestras'), findsOneWidget);
  });

  testWidgets('avisa cuando se usan datos locales', (tester) async {
    remote.failReads = true;
    await pumpApp(tester);

    expect(find.text('Mostrando datos locales'), findsOneWidget);
    expect(find.text('M-1003'), findsOneWidget);
  });
}
