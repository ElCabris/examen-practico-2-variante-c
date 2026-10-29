String _twoDigits(int value) => value.toString().padLeft(2, '0');

String formatDateTime(DateTime date) {
  final local = date.toLocal();
  return '${_twoDigits(local.day)}/${_twoDigits(local.month)}/${local.year} '
      '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}
