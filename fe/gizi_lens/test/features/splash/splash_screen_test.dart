import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/core/theme/app_theme.dart';
import 'package:gizi_lens/features/splash/controllers/splash_controller.dart';
import 'package:gizi_lens/features/splash/views/splash_screen.dart';

void main() {
  group('SplashScreen UI Tests', () {
    testWidgets('renders all essential elements from reference design 01 & 02',
        (WidgetTester tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SplashScreen(
            onCompleted: () {
              completed = true;
            },
          ),
        ),
      );

      // Verify Header
      expect(find.text(AppStrings.splashHeaderLeft), findsOneWidget);
      expect(find.text(AppStrings.splashHeaderRight), findsOneWidget);

      // Verify Tagline & Subtitle
      expect(find.text(AppStrings.tagline), findsOneWidget);
      expect(find.text(AppStrings.splashSubtitle), findsOneWidget);

      // Verify Nutrient Category Chips
      expect(find.text(AppStrings.nutrientPokok), findsOneWidget);
      expect(find.text(AppStrings.nutrientLauk), findsOneWidget);
      expect(find.text(AppStrings.nutrientSayur), findsOneWidget);
      expect(find.text(AppStrings.nutrientBuah), findsOneWidget);

      // Verify Initial Cloud Connection Status
      expect(find.text(AppStrings.cloudConnecting), findsOneWidget);
      expect(find.text(AppStrings.cloudVersion), findsOneWidget);

      // Verify Institution Footer
      expect(find.text(AppStrings.institutionBgn), findsOneWidget);
      expect(find.text(AppStrings.institutionSpk), findsOneWidget);

      // Settle progression
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(completed, isTrue);
    });
  });

  group('SplashController Unit Tests', () {
    test('progress increments smoothly and reaches completed state', () async {
      final controller = SplashController();
      bool completedCalled = false;

      controller.startInitialization(
        onCompleted: () {
          completedCalled = true;
        },
      );

      expect(controller.status, SplashStatus.connecting);
      expect(controller.progress, greaterThanOrEqualTo(0.05));

      // Wait for async initialization to complete reliably
      int waitMs = 0;
      while (!completedCalled && waitMs < 5000) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitMs += 100;
      }

      expect(controller.status, SplashStatus.completed);
      expect(controller.progress, 1.0);
      expect(completedCalled, isTrue);

      controller.dispose();
    });
  });
}
