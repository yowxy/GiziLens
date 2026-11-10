import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/core/services/firebase_auth_service.dart';
import 'package:gizi_lens/features/dashboard/controllers/dashboard_controller.dart';
import 'package:gizi_lens/features/dashboard/models/dashboard_stats_model.dart';
import 'package:gizi_lens/features/dashboard/views/dashboard_screen.dart';

void main() {
  group('DashboardController Unit Tests', () {
    late DashboardController controller;

    setUp(() {
      controller = DashboardController();
    });

    test('Initial states are correct', () {
      expect(controller.activeNavIndex, equals(0));
      expect(controller.selectedPeriod, equals(MonitoringPeriod.hariIni));
      expect(controller.hasUnreadNotifications, isTrue);
      expect(controller.stats.totalDiperiksa, equals(0));
      expect(controller.stats.totalSesuai, equals(0));
      expect(controller.stats.totalTidakSesuai, equals(0));
      expect(controller.greeting, equals(AppStrings.greetingWelcome));
      expect(controller.officerName, equals(AppStrings.dashboardOfficerName));
    });

    test('setNavIndex updates active navigation tab index', () {
      controller.setNavIndex(1);
      expect(controller.activeNavIndex, equals(1));
      controller.setNavIndex(2);
      expect(controller.activeNavIndex, equals(2));
      controller.setNavIndex(3);
      expect(controller.activeNavIndex, equals(3));
    });

    test('setPeriod updates selected monitoring period filter', () {
      controller.setPeriod(MonitoringPeriod.tujuhHari);
      expect(controller.selectedPeriod, equals(MonitoringPeriod.tujuhHari));
      expect(controller.stats.period, equals(MonitoringPeriod.tujuhHari));

      controller.setPeriod(MonitoringPeriod.tigaPuluhHari);
      expect(controller.selectedPeriod, equals(MonitoringPeriod.tigaPuluhHari));
    });

    test('loadNotifications sets the correct unread notification status', () {
      controller.loadNotifications();
      expect(controller.hasUnreadNotifications, isFalse);
    });

    test('formatNameFromEmail correctly extracts and capitalizes names', () {
      expect(
        FirebaseAuthService.formatNameFromEmail('iklilnajmi@gmail.com'),
        equals('Iklil Najmi'),
      );
      expect(
        FirebaseAuthService.formatNameFromEmail('budi.santoso@gmail.com'),
        equals('Budi Santoso'),
      );
    });
  });

  group('DashboardScreen Widget Tests', () {
    testWidgets('Renders all essential visual components from dashboard.png', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );

      // Verify Header Elements
      expect(find.text(AppStrings.greetingMorning), findsOneWidget);
      expect(find.text(AppStrings.dashboardOfficerName), findsOneWidget);
      expect(find.text(AppStrings.dashboardOfficerUnit), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

      // Verify Hero AI Camera Card
      expect(find.text(AppStrings.heroMenuTitle), findsOneWidget);
      expect(find.text(AppStrings.heroActionTitle), findsOneWidget);
      expect(find.text(AppStrings.heroActionBadge), findsOneWidget);
      expect(find.text(AppStrings.heroActionSubtitle), findsOneWidget);

      // Verify Period Filters
      expect(find.text(AppStrings.sectionMonitoringPeriod), findsOneWidget);
      expect(find.text(AppStrings.periodHariIni), findsOneWidget);
      expect(find.text(AppStrings.period7Hari), findsOneWidget);
      expect(find.text(AppStrings.period30Hari), findsOneWidget);

      // Verify AKG Compliance Section
      expect(find.text(AppStrings.sectionAkgSummary), findsOneWidget);
      expect(find.text(AppStrings.cardTotalTitle), findsOneWidget);
      expect(find.text(AppStrings.cardTotalDisclaimer), findsOneWidget);
      expect(find.text(AppStrings.cardSesuaiTitle), findsOneWidget);
      expect(find.text(AppStrings.cardSesuaiPill), findsOneWidget);
      expect(find.text(AppStrings.cardTidakSesuaiTitle), findsOneWidget);
      expect(find.text(AppStrings.cardTidakSesuaiPill), findsOneWidget);

      // Verify Bottom Navigation Bar
      expect(find.text(AppStrings.navBeranda), findsOneWidget);
      expect(find.text(AppStrings.navPeriksa), findsOneWidget);
      expect(find.text(AppStrings.navRiwayat), findsOneWidget);
      expect(find.text(AppStrings.navProfil), findsOneWidget);
    });

    testWidgets('Tapping period filter updates active selection', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );

      // Tap 7 Hari Terakhir
      await tester.tap(find.text(AppStrings.period7Hari));
      await tester.pumpAndSettle();

      // Tap 30 Hari Terakhir
      await tester.tap(find.text(AppStrings.period30Hari));
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping bottom nav items changes active tab', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );

      // Tap Riwayat tab
      await tester.tap(find.text(AppStrings.navRiwayat));
      await tester.pumpAndSettle();

      // Tap Profil tab
      await tester.tap(find.text(AppStrings.navProfil));
      await tester.pumpAndSettle();
    });
  });
}
