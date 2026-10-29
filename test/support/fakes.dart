import 'package:sample_track_shell/models/sample_event.dart';
import 'package:sample_track_shell/services/sample_event_remote_service.dart';

/// Firestore simulado en memoria con fallos configurables.
class FakeRemoteService implements SampleEventRemoteService {
  final List<SampleEvent> stored = [];
  bool failReads = false;
  bool failWrites = false;

  @override
  Future<List<SampleEvent>> getEvents() async {
    if (failReads) throw const RemoteDataException('Sin conexion (prueba).');
    return [...stored];
  }

  @override
  Future<List<SampleEvent>> getEventsForSample(String sampleId) async {
    final all = await getEvents();
    return all.where((event) => event.sampleId == sampleId).toList();
  }

  @override
  Future<void> saveEvent(SampleEvent event) async {
    if (failWrites) throw const RemoteDataException('Escritura rechazada.');
    stored.add(event);
  }
}

SampleEvent event(
  String sampleId,
  String type,
  DateTime createdAt,
) =>
    SampleEvent(
      id: '${sampleId}_${createdAt.microsecondsSinceEpoch}',
      sampleId: sampleId,
      type: type,
      createdAt: createdAt,
    );
