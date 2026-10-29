import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../models/sample_event.dart';
import '../models/sample_history.dart';
import '../models/sample_status.dart';
import '../services/sample_event_remote_service.dart';

enum EventSource { remote, local }

class SampleEventsResult {
  const SampleEventsResult({
    required this.events,
    required this.source,
    this.remoteError,
  });

  final List<SampleEvent> events;
  final EventSource source;

  final Object? remoteError;

  bool get isFromCache => source == EventSource.local;
}

class InvalidTransitionException implements Exception {
  const InvalidTransitionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SampleEventRepository {
  SampleEventRepository({
    required AppDatabase database,
    required SampleEventRemoteService remote,
  })  : _database = database,
        _remote = remote;

  final AppDatabase _database;
  final SampleEventRemoteService _remote;

  Future<SampleEventsResult> getAllEvents() => _load(
        remote: _remote.getEvents,
        local: _database.getAllEvents,
      );

  Future<SampleEventsResult> getEventsForSample(String sampleId) => _load(
        remote: () => _remote.getEventsForSample(sampleId),
        local: () => _database.getEventsForSample(sampleId),
      );

  Future<void> registerEvent(SampleEvent event) async {
    final current = await getEventsForSample(event.sampleId);
    validateTransition(SampleHistory(current.events), event);

    await _remote.saveEvent(event);

    try {
      await _database.upsertEvent(event);
    } catch (error) {
      debugPrint('No se pudo guardar el evento en Drift: $error');
    }
  }

  static void validateTransition(SampleHistory history, SampleEvent event) {
    final requested = event.status;
    if (requested == null) {
      throw InvalidTransitionException(
          'Tipo de evento desconocido: ${event.type}.');
    }
    final expected = history.nextStatus;
    if (expected == null) {
      throw const InvalidTransitionException(
        'La muestra ya está Archivada; no hay un siguiente evento válido.',
      );
    }
    if (requested != expected) {
      throw InvalidTransitionException(
        'Transición inválida: de ${SampleStatus.labelOf(history.status)} '
        'solo se puede pasar a ${expected.label} (${expected.code}).',
      );
    }
  }

  Future<SampleEventsResult> _load({
    required Future<List<SampleEvent>> Function() remote,
    required Future<List<SampleEvent>> Function() local,
  }) async {
    final List<SampleEvent> events;
    try {
      events = await remote();
    } catch (error) {
      debugPrint('Lectura remota fallida, usando Drift: $error');
      return SampleEventsResult(
        events: await local(),
        source: EventSource.local,
        remoteError: error,
      );
    }

    try {
      await _database.upsertEvents(events);
    } catch (error) {
      debugPrint('No se pudo actualizar la cache local: $error');
    }
    return SampleEventsResult(events: events, source: EventSource.remote);
  }
}
