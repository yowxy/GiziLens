import 'package:flutter_test/flutter_test.dart';

import 'package:gizi_lens/core/services/scan_quota_service.dart';

void main() {
  group('ScanQuota', () {
    final periodStart =
        DateTime.utc(2026, 10, 31, 17);

    test('quota exhausted at limit', () {
      final quota = ScanQuota(
        used: 10,
        limit: 10,
        periodStart: periodStart,
      );

      expect(quota.isExhausted, isTrue);
      expect(quota.remaining, 0);
      expect(quota.progress, 1.0);
    });

    test('scanning allowed below limit', () {
      final quota = ScanQuota(
        used: 9,
        limit: 10,
        periodStart: periodStart,
      );

      expect(quota.isExhausted, isFalse);
      expect(quota.remaining, 1);
      expect(
        quota.progress,
        closeTo(0.9, 0.0001),
      );
    });

    test('remaining cannot be negative', () {
      final quota = ScanQuota(
        used: 520,
        limit: 500,
        periodStart: periodStart,
      );

      expect(quota.remaining, 0);
      expect(quota.progress, 1.0);
    });

    test('reserved scan reduces remaining quota', () {
      final quota = ScanQuota(
        used: 9,
        reserved: 1,
        limit: 10,
        periodStart: periodStart,
      );

      expect(quota.used, 9);
      expect(quota.remaining, 0);
      expect(quota.isExhausted, isTrue);
    });

    test('unavailable quota is not confirmed exhausted', () {
      final quota = ScanQuota(
        used: 10,
        limit: 10,
        periodStart: periodStart,
        available: false,
      );

      expect(quota.available, isFalse);
      expect(quota.isExhausted, isFalse);
    });

    test('period ends at next calendar month', () {
      final quota = ScanQuota(
        used: 0,
        limit: 10,
        periodStart: periodStart,
      );

      expect(
        quota.periodEnd,
        DateTime.utc(2026, 11, 30, 17),
      );

      final decemberQuota = ScanQuota(
        used: 0,
        limit: 10,
        periodStart:
            DateTime.utc(2026, 11, 30, 17),
      );

      expect(
        decemberQuota.periodEnd,
        DateTime.utc(2026, 12, 31, 17),
      );
    });

    test('default plan allowances', () {
      expect(
        ScanQuotaService.freeMonthlyQuota,
        10,
      );

      expect(
        ScanQuotaService.premiumMonthlyQuota,
        500,
      );
    });
  });
}
