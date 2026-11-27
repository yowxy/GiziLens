import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/services/scan_quota_service.dart';

void main() {
  group('ScanQuota', () {
    final periodStart = DateTime.utc(2026, 10, 31, 17);

    test('is exhausted once the used count reaches the limit', () {
      final quota = ScanQuota(used: 10, limit: 10, periodStart: periodStart);

      expect(quota.isExhausted, isTrue);
      expect(quota.remaining, 0);
      expect(quota.progress, 1.0);
    });

    test('still allows scanning below the limit', () {
      final quota = ScanQuota(used: 9, limit: 10, periodStart: periodStart);

      expect(quota.isExhausted, isFalse);
      expect(quota.remaining, 1);
      expect(quota.progress, closeTo(0.9, 0.0001));
    });

    test('remaining never goes negative when usage overshoots', () {
      final quota = ScanQuota(used: 520, limit: 500, periodStart: periodStart);

      expect(quota.remaining, 0);
      expect(quota.progress, 1.0);
    });

    test('period end points at the first day of the next month', () {
      expect(ScanQuota(used: 0, limit: 10, periodStart: periodStart).periodEnd,
          DateTime.utc(2026, 11, 30, 17));
      expect(
        ScanQuota(used: 0, limit: 10, periodStart: DateTime.utc(2026, 11, 30, 17))
            .periodEnd,
        DateTime.utc(2026, 12, 31, 17),
      );
    });

    test('plan allowances match the published pricing', () {
      expect(ScanQuotaService.freeMonthlyQuota, 10);
      expect(ScanQuotaService.premiumMonthlyQuota, 500);
    });
  });
}
