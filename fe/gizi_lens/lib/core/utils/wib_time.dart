/// Calendar and reporting boundaries for Western Indonesia Time (UTC+7).
abstract final class WibTime {
  static const _offset = Duration(hours: 7);

  /// Calendar fields for display only. Persist and compare the original instant.
  static DateTime calendar(DateTime instant) => instant.toUtc().add(_offset);

  /// Older mobile clients wrote WIB wall time without an offset.
  static DateTime? parseInstant(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    final timestamp = text.contains(RegExp(r'[Tt ]')) ? text : '${text}T00:00:00';
    return DateTime.tryParse('$timestamp+07:00') ??
        DateTime.tryParse(timestamp)?.toUtc();
  }

  static DateTime startOfDayUtc(DateTime instant) {
    final day = calendar(instant);
    return DateTime.utc(day.year, day.month, day.day).subtract(_offset);
  }

  static DateTime startOfMonthUtc(DateTime instant, {int monthsAhead = 0}) {
    final day = calendar(instant);
    return DateTime.utc(day.year, day.month + monthsAhead).subtract(_offset);
  }
}
