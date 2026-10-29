import 'sample_event.dart';
import 'sample_status.dart';

class SampleHistory {
  SampleHistory(Iterable<SampleEvent> events)
      : events = List.unmodifiable(
          events.where((event) => event.status != null).toList()
            ..sort(_chronological),
        );

  final List<SampleEvent> events;

  bool get isEmpty => events.isEmpty;

  SampleEvent? get latestEvent => events.isEmpty ? null : events.last;

  SampleStatus? get status => latestEvent?.status;

  DateTime? get lastUpdate => latestEvent?.createdAt;

  SampleStatus? get nextStatus => SampleStatus.nextAfter(status);

  bool get isArchived => status == SampleStatus.archived;

  static int _chronological(SampleEvent a, SampleEvent b) {
    final byDate = a.createdAt.compareTo(b.createdAt);
    if (byDate != 0) return byDate;
    return a.status!.order.compareTo(b.status!.order);
  }
}
