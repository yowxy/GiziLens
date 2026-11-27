import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/core/services/firestore_service.dart';
import 'package:gizi_lens/features/profile/controllers/profile_controller.dart';
import 'package:gizi_lens/features/profile/views/dialogs/profile_updated_success_dialog.dart';
import 'package:gizi_lens/features/profile/views/profile_screen.dart';
import 'package:gizi_lens/features/profile/views/widgets/officer_info_hero_card.dart';
import 'package:gizi_lens/features/profile/views/widgets/profile_header_app_bar.dart';

void main() {
  group('ProfileController Unit Tests', () {
    late ProfileController controller;

    setUp(() {
      ProfileController.resetForTesting();
      controller = ProfileController();
    });

    test('Initial profile states are correctly initialized', () {
      expect(controller.activeNavIndex, equals(3));
      expect(controller.notificationsEnabled, isTrue);
    });

    test('updateProfileName updates name and computes initials', () {
      controller.updateProfileName('Siti Rahma, S.Gz');
      expect(controller.account.fullName, equals('Siti Rahma, S.Gz'));
      expect(controller.account.initials, equals('SR'));
    });

    test('updateProfile updates fullName, role, unit, and region', () async {
      final success = await controller.updateProfile(
        fullName: 'Budi Santoso, S.Tr.Gz',
        role: 'Supervisor SPPG',
        unit: 'SPPG Cibinong Sentral 01',
        region: 'Kab. Bogor',
      );
      expect(success, isTrue);
      expect(controller.account.fullName, equals('Budi Santoso, S.Tr.Gz'));
      expect(controller.account.roleTitle, equals('Supervisor SPPG'));
      expect(
        controller.account.unitOperational,
        equals('SPPG Cibinong Sentral 01'),
      );
      expect(controller.account.unitRegion, equals('Kab. Bogor'));
      expect(controller.account.initials, equals('BS'));
    });

    test('toggleNotifications toggles flag and notifies listeners', () {
      controller.toggleNotifications(false);
      expect(controller.notificationsEnabled, isFalse);
    });

    test('FirestoreService preserves officer fullName, role, unit, and region', () async {
      await FirestoreService.instance.saveUserProfile(
        uid: 'test-uid-123',
        data: {
          'fullName': 'Fita Andini, S.Gz',
          'role': 'Ahli Gizi Lapangan',
          'unit': 'SPPG Cibinong Sentral 02',
          'region': 'Kab. Bogor, Jawa Barat',
          'officerId': 'BGN-2026-TEST1',
        },
      );

      final loaded = await FirestoreService.instance.getUserProfile('test-uid-123');
      expect(loaded, isNotNull);
      expect(loaded!['fullName'], equals('Fita Andini, S.Gz'));
      expect(loaded['role'], equals('Ahli Gizi Lapangan'));
      expect(loaded['unit'], equals('SPPG Cibinong Sentral 02'));
      expect(loaded['region'], equals('Kab. Bogor, Jawa Barat'));
      expect(loaded['officerId'], equals('BGN-2026-TEST1'));
    });
  });

  group('ProfileScreen Widget Tests', () {
    testWidgets('Renders all profile header and officer card elements', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileHeaderAppBar), findsOneWidget);
      expect(find.text(AppStrings.profileScreenTitle), findsOneWidget);
      expect(find.text(AppStrings.profileScreenSubtitle), findsOneWidget);

      expect(find.byType(OfficerInfoHeroCard), findsOneWidget);
      expect(find.text(AppStrings.btnEditProfile), findsOneWidget);

      expect(find.text(AppStrings.planFreeName), findsOneWidget);
      expect(find.text(AppStrings.planActiveLabel), findsOneWidget);
      expect(find.text(AppStrings.planQuotaTitle), findsOneWidget);
      expect(find.text(AppStrings.btnUpgradePremium), findsOneWidget);

      expect(find.text(AppStrings.sectionPreferenceTitle), findsOneWidget);
      expect(find.text(AppStrings.menuAkgTitle), findsOneWidget);
      expect(find.text(AppStrings.menuNotificationTitle), findsOneWidget);

      expect(find.text(AppStrings.sectionHelpTitle), findsOneWidget);
      expect(find.text(AppStrings.menuSopTitle), findsOneWidget);
      expect(find.text(AppStrings.menuHelpdeskTitle), findsOneWidget);

      expect(find.text(AppStrings.btnLogoutAccount), findsOneWidget);
    });

    testWidgets('Edit profile modal saves and updates OfficerInfoHeroCard', (
      tester,
    ) async {
      ProfileController.resetForTesting();
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.btnEditProfile));
      await tester.pumpAndSettle();

      expect(find.text('Edit Data Petugas SPPG'), findsOneWidget);

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(4));

      await tester.enterText(fields.at(0), 'Nurul Anggraini, S.Gz');
      await tester.enterText(fields.at(1), 'Ahli Gizi Lapangan');
      await tester.enterText(fields.at(2), 'SPPG Cibinong Sentral 02');
      await tester.enterText(fields.at(3), 'Kab. Bogor, Jawa Barat');

      await tester.tap(find.text('Simpan Profil'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileUpdatedSuccessDialog), findsOneWidget);
      await tester.tap(find.text(AppStrings.profileUpdatedBackButton));
      await tester.pumpAndSettle();

      expect(find.text('Nurul Anggraini, S.Gz'), findsOneWidget);
      expect(find.text('Kab. Bogor, Jawa Barat'), findsOneWidget);
    });
  });
}
