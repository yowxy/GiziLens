import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/features/profile/controllers/profile_controller.dart';
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
      expect(controller.account.unitOperational, equals('SPPG Cibinong Sentral 01'));
      expect(controller.account.unitRegion, equals('Kab. Bogor'));
      expect(controller.account.initials, equals('BS'));
    });

    test('toggleNotifications toggles flag and notifies listeners', () {
      controller.toggleNotifications(false);
      expect(controller.notificationsEnabled, isFalse);
    });
  });

  group('ProfileScreen Widget Tests', () {
    testWidgets('Renders all profile header and officer card elements', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileHeaderAppBar), findsOneWidget);
      expect(find.text(AppStrings.profileScreenTitle), findsOneWidget);
      expect(find.text(AppStrings.profileScreenSubtitle), findsOneWidget);

      expect(find.byType(OfficerInfoHeroCard), findsOneWidget);
      expect(find.text(AppStrings.btnEditProfile), findsOneWidget);

      expect(find.text(AppStrings.sectionPreferenceTitle), findsOneWidget);
      expect(find.text(AppStrings.menuAkgTitle), findsOneWidget);
      expect(find.text(AppStrings.menuNotificationTitle), findsOneWidget);

      expect(find.text(AppStrings.sectionHelpTitle), findsOneWidget);
      expect(find.text(AppStrings.menuSopTitle), findsOneWidget);
      expect(find.text(AppStrings.menuHelpdeskTitle), findsOneWidget);

      expect(find.text(AppStrings.btnLogoutAccount), findsOneWidget);
    });
  });
}
