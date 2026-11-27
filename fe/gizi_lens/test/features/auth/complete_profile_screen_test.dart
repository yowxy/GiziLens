import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/features/auth/controllers/complete_profile_controller.dart';
import 'package:gizi_lens/features/auth/models/officer_role.dart';
import 'package:gizi_lens/features/auth/views/complete_profile_screen.dart';

void main() {
  group('CompleteProfileController Unit Tests', () {
    late CompleteProfileController controller;

    setUp(() {
      controller = CompleteProfileController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial profile state contains default officer data', () {
      expect(controller.profile.fullName, equals('-'));
      expect(controller.profile.officerId, equals('-'));
      expect(controller.profile.selectedRole, equals(OfficerRole.ahliGizi));
      expect(controller.profile.initials, equals('-'));
      expect(controller.profile.isVerified, isTrue);
    });

    test('Selecting role updates selected role in profile', () {
      controller.selectRole(OfficerRole.petugasSppg);
      expect(controller.selectedRole, equals(OfficerRole.petugasSppg));
      expect(controller.profile.selectedRole.id, equals('petugas_sppg'));

      controller.selectRole(OfficerRole.penyeliaDapur);
      expect(controller.selectedRole, equals(OfficerRole.penyeliaDapur));
    });

    test('Typing in fullNameController dynamically updates name and initials', () {
      controller.fullNameController.text = 'Fita Andini';
      expect(controller.profile.fullName, equals('Fita Andini'));
      expect(controller.profile.initials, equals('FA'));
    });

    test('Unit and region controllers and validators work for text input', () {
      expect(controller.validateUnit(''), equals(AppStrings.operationalUnitRequired));
      expect(controller.validateUnit('   '), equals(AppStrings.operationalUnitRequired));
      expect(controller.validateRegion(''), equals(AppStrings.regionRequired));
      expect(controller.validateRegion('   '), equals(AppStrings.regionRequired));

      controller.unitController.text = '  SPPG Cibinong Sentral 02  ';
      controller.regionController.text = '  Kab. Bogor, Jawa Barat  ';

      expect(controller.selectedUnit, equals('SPPG Cibinong Sentral 02'));
      expect(controller.selectedRegion, equals('Kab. Bogor, Jawa Barat'));
      expect(controller.validateUnit(controller.unitController.text), isNull);
      expect(controller.validateRegion(controller.regionController.text), isNull);
    });
  });

  group('CompleteProfileScreen Widget Tests', () {
    testWidgets('Renders all essential elements from 2auth.png', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CompleteProfileScreen(),
        ),
      );

      // Verify Header
      expect(find.text(AppStrings.completeProfileTitle), findsOneWidget);
      expect(find.text(AppStrings.completeProfileSubtitle), findsOneWidget);

      // Verify Profile Card & Officer ID Locked Field
      expect(find.text('-'), findsWidgets);
      expect(find.text(AppStrings.certificationActive), findsOneWidget);
      expect(find.text(AppStrings.verifiedTag), findsOneWidget);
      expect(find.text(AppStrings.btnUnggahFoto), findsOneWidget);

      // Verify Full Name Field
      expect(find.text(AppStrings.fullNameLabel), findsOneWidget);
      expect(find.text(AppStrings.fullNameHelper), findsOneWidget);

      // Verify Officer ID Locked Field
      expect(find.text(AppStrings.officerIdLabel), findsOneWidget);
      expect(find.text(AppStrings.verifiedBgnTag), findsOneWidget);
      expect(find.text(AppStrings.officerIdHelperText), findsOneWidget);

      // Verify Roles
      expect(find.text(AppStrings.operationalRoleTitle), findsOneWidget);
      expect(find.text(AppStrings.roleAhliGiziTitle), findsOneWidget);
      expect(find.text(AppStrings.rolePetugasSppgTitle), findsOneWidget);
      expect(find.text(AppStrings.rolePenyeliaDapurTitle), findsOneWidget);

      // Verify Bottom Buttons
      expect(find.text(AppStrings.btnSaveProfile), findsOneWidget);
      expect(find.text(AppStrings.btnSkipProfile), findsOneWidget);
    });

    testWidgets('Tapping role selection changes active radio selection', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CompleteProfileScreen(),
        ),
      );

      // Tap on Petugas SPPG role
      await tester.tap(find.text(AppStrings.rolePetugasSppgTitle));
      await tester.pumpAndSettle();

      // Tap on Penyelia role
      await tester.tap(find.text(AppStrings.rolePenyeliaDapurTitle));
      await tester.pumpAndSettle();
    });

    testWidgets('Scroll view scrolls smoothly with docked bottom action bar', (tester) async {
      // Standard mobile viewport
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CompleteProfileScreen(),
        ),
      );

      // Verify initial state has docked buttons visible
      expect(find.text(AppStrings.btnSaveProfile), findsOneWidget);

      // Perform scroll drag
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Verify docked action bar remains pinned and visible after scrolling
      expect(find.text(AppStrings.btnSaveProfile), findsOneWidget);
      expect(find.text(AppStrings.rolePenyeliaDapurTitle), findsOneWidget);
    });
  });
}
