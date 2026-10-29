import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/sample_event.dart';

class RemoteDataException implements Exception {
  const RemoteDataException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class SampleEventRemoteService {
  SampleEventRemoteService({FirebaseFirestore? firestore})
      : _firestore = firestore;

  static const collectionName = 'sample_events';
  static const _timeout = Duration(seconds: 8);

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(collectionName);

  Future<List<SampleEvent>> getEvents() => _guard(() async {
        final snapshot = await _collection.get(_serverOnly).timeout(_timeout);
        return _parseDocuments(snapshot.docs);
      });

  Future<List<SampleEvent>> getEventsForSample(String sampleId) =>
      _guard(() async {
        final snapshot = await _collection
            .where('sampleId', isEqualTo: sampleId)
            .get(_serverOnly)
            .timeout(_timeout);
        return _parseDocuments(snapshot.docs);
      });

  Future<void> saveEvent(SampleEvent event) => _guard(() async {
        final document = _collection.doc(event.id);
        await _db.runTransaction<void>(
          (transaction) async {
            final existing = await transaction.get(document);
            if (existing.exists) {
              throw RemoteDataException(
                  'Ya existe un evento con id ${event.id}.');
            }
            transaction.set(document, _toMap(event));
          },
          timeout: _timeout,
          maxAttempts: 1,
        ).timeout(_timeout + const Duration(seconds: 2));
      });

  static const _serverOnly = GetOptions(source: Source.server);

  static Map<String, dynamic> _toMap(SampleEvent event) => {
        'id': event.id,
        'sampleId': event.sampleId,
        'type': event.type,
        'createdAt': Timestamp.fromDate(event.createdAt),
      };

  static List<SampleEvent> _parseDocuments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final events = <SampleEvent>[];
    for (final document in documents) {
      try {
        events.add(_fromDocument(document));
      } catch (error) {
        debugPrint('Documento ${document.id} ignorado: $error');
      }
    }
    return events;
  }

  static SampleEvent _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return SampleEvent(
      id: data['id'] as String? ?? document.id,
      sampleId: data['sampleId'] as String,
      type: data['type'] as String,
      createdAt: _parseDate(data['createdAt']),
    );
  }

  static DateTime _parseDate(Object? value) => switch (value) {
        Timestamp timestamp => timestamp.toDate(),
        String text => DateTime.parse(text),
        _ => throw FormatException('createdAt inválido: $value'),
      };

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on RemoteDataException {
      rethrow;
    } on TimeoutException catch (error) {
      throw RemoteDataException('Firestore no respondió a tiempo.', error);
    } on FirebaseException catch (error) {
      if (error.code == 'no-app') {
        throw RemoteDataException('Firebase no está inicializado.', error);
      }
      throw RemoteDataException(
        'Firestore no disponible (${error.code}).',
        error,
      );
    } catch (error) {
      throw RemoteDataException(
          'No fue posible conectar con Firestore.', error);
    }
  }
}
