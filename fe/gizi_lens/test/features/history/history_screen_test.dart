import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/features/history/controllers/history_controller.dart';
import 'package:gizi_lens/features/history/models/history_filter_model.dart';
import 'package:gizi_lens/features/history/views/history_screen.dart';

void main() {
  group('HistoryController Unit Tests', () {
    late HistoryController controller;

    setUp(() {
      controller = HistoryController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial states are correct', () {
      expect(controller.activeTab, equals(HistoryTab.semua));
      expect(controller.activeDateFilter, equals(HistoryDateFilter.hariIni));
      expect(controller.hasNotification, isTrue);
      expect(controller.filter.searchQuery, isEmpty);
    });

    test('setTab updates active tab filter', () {
      controller.setTab(HistoryTab.sesuai);
      expect(controller.activeTab, equals(HistoryTab.sesuai));

      controller.setTab(HistoryTab.tidakSesuai);
      expect(controller.activeTab, equals(HistoryTab.tidakSesuai));
    });

    test('setDateFilter updates active date range', () {
      controller.setDateFilter(HistoryDateFilter.tujuhHari);
      expect(controller.activeDateFilter, equals(HistoryDateFilter.tujuhHari));

      controller.setDateFilter(HistoryDateFilter.tigaPuluhHari);
      expect(controller.activeDateFilter, equals(HistoryDateFilter.tigaPuluhHari));
    });

    test('dismissNotification clears unread notification dot', () {
      controller.dismissNotification();
      expect(controller.hasNotification, isFalse);
    });

    test('search text updates search query in filter model', () {
      controller.searchController.text = 'Bayam';
      expect(controller.filter.searchQuery, equals('Bayam'));

      controller.clearSearch();
      expect(controller.filter.searchQuery, isEmpty);
      expect(controller.searchController.text, isEmpty);
    });
  });

  group('HistoryScreen Widget Tests', () {
    testWidgets('Renders all essential visual components from history.png', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );

      // Verify Header Elements
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.text(AppStrings.monitoringGiziMbgBadge), findsOneWidget);
      expect(find.text(AppStrings.historyTitle), findsOneWidget);
      expect(find.text(AppStrings.historySubtitle), findsOneWidget);
      expect(find.text(AppStrings.searchHistoryHint), findsOneWidget);

      // Verify Category Tabs
      expect(find.text(AppStrings.tabSemua), findsOneWidget);
      expect(find.text(AppStrings.tabSesuai), findsOneWidget);
      expect(find.text(AppStrings.tabTidakSesuai), findsOneWidget);

      // Verify Date Filter Chips
      expect(find.text(AppStrings.periodHariIni), findsOneWidget);
      expect(find.text(AppStrings.period7Hari), findsOneWidget);
      expect(find.text(AppStrings.period30Hari), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      // Verify Empty State
      expect(find.text(AppStrings.emptyHistoryTitle), findsOneWidget);

      // Verify Bottom Navigation Bar with Riwayat Active
      expect(find.text(AppStrings.navBeranda), findsOneWidget);
      expect(find.text(AppStrings.navPeriksa), findsOneWidget);
      expect(find.text(AppStrings.navRiwayat), findsOneWidget);
      expect(find.text(AppStrings.navProfil), findsOneWidget);
    });

    testWidgets('Tapping category tabs updates active selection', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );

      // Tap Sesuai tab
      await tester.tap(find.text(AppStrings.tabSesuai));
      await tester.pumpAndSettle();

      // Tap Tidak Sesuai tab
      await tester.tap(find.text(AppStrings.tabTidakSesuai));
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping date filter chips updates active selection', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );

      // Tap 7 Hari Terakhir
      await tester.tap(find.text(AppStrings.period7Hari));
      await tester.pumpAndSettle();

      // Tap 30 Hari Terakhir
      await tester.tap(find.text(AppStrings.period30Hari));
      await tester.pumpAndSettle();
    });
  });
}
