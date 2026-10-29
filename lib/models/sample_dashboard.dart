import 'sample.dart';
import 'sample_event.dart';
import 'sample_history.dart';
import 'sample_status.dart';

const samplePriorities = ['Urgente', 'Alta', 'Normal'];

const statusOptions = <SampleStatus?>[null, ...SampleStatus.values];

int priorityRank(String priority) {
  final rank = samplePriorities.indexOf(priority);
  return rank == -1 ? samplePriorities.length : rank;
}

class SampleOverview {
  const SampleOverview({required this.sample, required this.history});

  final Sample sample;
  final SampleHistory history;

  SampleStatus? get status => history.status;
  DateTime? get lastUpdate => history.lastUpdate;
}

class SampleFilter {
  const SampleFilter({
    this.status = allStatuses,
    this.priority = allPriorities,
  });

  static const allStatuses = 'Todos';
  static const allPriorities = 'Todas';

  final String status;

  final String priority;

  bool matches(SampleOverview overview) =>
      (status == allStatuses ||
          SampleStatus.labelOf(overview.status) == status) &&
      (priority == allPriorities || overview.sample.priority == priority);

  SampleFilter copyWith({String? status, String? priority}) => SampleFilter(
        status: status ?? this.status,
        priority: priority ?? this.priority,
      );
}

class SampleDashboard {
  SampleDashboard({
    required List<Sample> samples,
    required Iterable<SampleEvent> events,
  }) : overviews = [
          for (final sample in samples)
            SampleOverview(
              sample: sample,
              history: SampleHistory(
                events.where((event) => event.sampleId == sample.id),
              ),
            ),
        ];

  final List<SampleOverview> overviews;

  int get total => overviews.length;

  List<SampleOverview> visible(SampleFilter filter) =>
      overviews.where(filter.matches).toList()..sort(_byPriorityAndUpdate);

  Map<SampleStatus?, int> countsByStatus() {
    final counts = <SampleStatus?, int>{
      null: 0,
      for (final status in SampleStatus.values) status: 0,
    };
    for (final overview in overviews) {
      counts[overview.status] = counts[overview.status]! + 1;
    }
    return counts;
  }

  List<SampleOverview> requiringAttention() =>
      overviews.where((overview) => !overview.history.isArchived).toList()
        ..sort(_byPriorityAndUpdate);

  static int _byPriorityAndUpdate(SampleOverview a, SampleOverview b) {
    final byPriority =
        priorityRank(a.sample.priority) - priorityRank(b.sample.priority);
    if (byPriority != 0) return byPriority;
    final byUpdate = _compareUpdates(a.lastUpdate, b.lastUpdate);
    if (byUpdate != 0) return byUpdate;
    return a.sample.id.compareTo(b.sample.id);
  }

  static int _compareUpdates(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }
}
