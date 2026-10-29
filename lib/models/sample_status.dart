enum SampleStatus {
  received('RECEIVED', 'Recibida'),
  prepared('PREPARED', 'Preparada'),
  inAnalysis('IN_ANALYSIS', 'En análisis'),
  validated('VALIDATED', 'Validada'),
  archived('ARCHIVED', 'Archivada');

  const SampleStatus(this.code, this.label);

  final String code;
  final String label;

  static const noEventsLabel = 'Sin eventos';

  int get order => index + 1;

  static SampleStatus? fromCode(String code) {
    for (final status in values) {
      if (status.code == code) return status;
    }
    return null;
  }

  static SampleStatus? nextAfter(SampleStatus? current) {
    if (current == null) return received;
    final nextIndex = current.index + 1;
    return nextIndex < values.length ? values[nextIndex] : null;
  }

  static String labelOf(SampleStatus? status) => status?.label ?? noEventsLabel;
}
