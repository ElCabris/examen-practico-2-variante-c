import 'sample_status.dart';

class SampleEvent {
  const SampleEvent({
    required this.id,
    required this.sampleId,
    required this.type,
    required this.createdAt,
  });

  factory SampleEvent.create({
    required String sampleId,
    required SampleStatus status,
    DateTime? createdAt,
  }) {
    final timestamp = createdAt ?? DateTime.now();
    return SampleEvent(
      id: '${sampleId}_${timestamp.microsecondsSinceEpoch}',
      sampleId: sampleId,
      type: status.code,
      createdAt: timestamp,
    );
  }

  final String id;
  final String sampleId;
  final String type;
  final DateTime createdAt;

  SampleStatus? get status => SampleStatus.fromCode(type);
}
