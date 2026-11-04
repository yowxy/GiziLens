import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/core/theme/app_theme.dart';
import 'package:gizi_lens/features/onboarding/views/onboarding_screen.dart';

void main() {
  group('OnboardingScreen UI Tests', () {
    testWidgets('renders Page 1 (Scan Ompreng) elements accurately',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const OnboardingScreen(),
        ),
      );

      // Verify Page 1 Title & Description
      expect(find.text(AppStrings.onboarding1Title), findsOneWidget);
      expect(find.text(AppStrings.onboarding1Desc), findsOneWidget);
      expect(find.text(AppStrings.onboarding1Badge), findsOneWidget);

      // Verify AI & MBG Status
      expect(find.text(AppStrings.aiAktif), findsOneWidget);
      expect(find.text(AppStrings.standarGiziMbg), findsOneWidget);
      expect(find.text(AppStrings.kkal465), findsOneWidget);

      // Verify Buttons
      expect(find.text(AppStrings.btnLanjutkan), findsOneWidget);
      expect(find.text(AppStrings.btnLewati), findsOneWidget);
    });

    testWidgets('navigates to Page 2 (Nutrisi Seimbang) on Lanjutkan tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const OnboardingScreen(),
        ),
      );

      // Tap Lanjutkan button
      await tester.tap(find.text(AppStrings.btnLanjutkan));
      await tester.pumpAndSettle();

      // Verify Page 2 Title & Description
      expect(find.text(AppStrings.onboarding2Title), findsOneWidget);
      expect(find.text(AppStrings.onboarding2Desc), findsOneWidget);
      expect(find.text(AppStrings.onboarding2Badge), findsOneWidget);

      // Verify Smart Badges
      expect(find.text(AppStrings.skorGizi), findsOneWidget);
      expect(find.text(AppStrings.lengkapDanSehat), findsOneWidget);
      expect(find.text(AppStrings.energiOptimal), findsOneWidget);
      expect(find.text(AppStrings.kkal520), findsOneWidget);

      // Verify Plate Composition Card
      expect(find.text(AppStrings.plateCompositionTitle), findsOneWidget);
      expect(find.text(AppStrings.plateIdealBadge), findsOneWidget);
      expect(find.text(AppStrings.karbo), findsOneWidget);
      expect(find.text(AppStrings.karboPct), findsOneWidget);
      expect(find.text(AppStrings.protein), findsOneWidget);
      expect(find.text(AppStrings.proteinPct), findsOneWidget);
      expect(find.text(AppStrings.serat), findsOneWidget);
      expect(find.text(AppStrings.seratPct), findsOneWidget);

      // Verify Page 2 Final Action Button
      expect(find.text(AppStrings.btnMulaiSekarang), findsOneWidget);
    });
  });
}
