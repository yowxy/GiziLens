import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/utils/wib_time.dart';

void main() {
  test('UTC, explicit offsets and legacy WIB text identify the same scan', () {
    final instant = DateTime.utc(2026, 11, 27, 12, 38);
    for (final timestamp in [
      '2026-11-27T12:38:00Z',
      '2026-11-27T12:38:00+00:00',
      '2026-11-27T19:38:00+07:00',
      '2026-11-27T21:38:00+09:00',
      '2026-11-27T19:38:00',
    ]) {
      final parsed = WibTime.parseInstant(timestamp);
      expect(parsed, instant);
      final wib = WibTime.calendar(parsed!);
      expect([wib.day, wib.hour, wib.minute], [27, 19, 38]);
    }
    expect(WibTime.parseInstant('2026-11-28'), DateTime.utc(2026, 11, 27, 17));
    expect(WibTime.parseInstant(null), isNull);
    expect(WibTime.parseInstant('invalid'), isNull);
  });

  test('midnight in Jakarta changes the reporting day, month and year', () {
    final midnight = DateTime.utc(2026, 12, 31, 17);
    final before = midnight.subtract(const Duration(microseconds: 1));
    expect(WibTime.startOfDayUtc(before), DateTime.utc(2026, 12, 30, 17));
    expect(WibTime.startOfMonthUtc(before), DateTime.utc(2026, 11, 30, 17));
    expect(WibTime.startOfDayUtc(midnight), midnight);
    expect(WibTime.startOfMonthUtc(midnight), midnight);
    expect(WibTime.calendar(midnight).year, 2027);
  });
}
