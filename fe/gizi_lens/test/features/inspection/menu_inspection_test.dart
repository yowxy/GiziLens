import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/features/inspection/controllers/menu_inspection_controller.dart';
import 'package:gizi_lens/features/inspection/models/target_akg_model.dart';
import 'package:gizi_lens/features/inspection/views/menu_inspection_screen.dart';
import 'package:gizi_lens/features/inspection/views/widgets/batch_definition_banner.dart';
import 'package:gizi_lens/features/inspection/views/widgets/locked_batch_field.dart';
import 'package:gizi_lens/features/inspection/views/widgets/step_progress_app_bar.dart';
import 'package:gizi_lens/features/inspection/views/widgets/target_group_selector.dart';

void main() {
  group('TargetAkgModel Unit Tests', () {
    test('Standard presets are properly configured with 5 demographics', () {
      expect(TargetAkgModel.standardPresets.length, equals(5));
      expect(TargetAkgModel.standardPresets[0].calories, equals(450));
      expect(TargetAkgModel.standardPresets[1].calories, equals(620));
      expect(TargetAkgModel.standardPresets[1].formattedSummary, equals('620 kkal • Protein 18–22g'));
    });
  });

  group('MenuInspectionController Unit Tests', () {
    late MenuInspectionController controller;

    setUp(() {
      controller = MenuInspectionController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial states match reference design specifications', () {
      expect(controller.batchCode, equals('MBG-2026-001'));
      expect(controller.sppgUnit, equals(AppStrings.defaultSppgUnit));
      expect(controller.selectedTargetAkg.groupName, equals('SD Kelas 4 – 6 (10 – 12 Tahun)'));
      expect(controller.schoolController.text, equals(AppStrings.defaultSchoolDestination));
      expect(controller.notesController.text, equals(AppStrings.defaultInspectionNotes));
      expect(controller.isValid, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('selectTargetAkg updates demographic model and triggers notification', () {
      var notified = false;
      controller.addListener(() => notified = true);

      final newPreset = TargetAkgModel.standardPresets[3]; // SMA / SMK
      controller.selectTargetAkg(newPreset);

      expect(controller.selectedTargetAkg, equals(newPreset));
      expect(notified, isTrue);
    });

    test('setSchoolDestination updates destination text and notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.setSchoolDestination('SMPN 3 Cibinong');

      expect(controller.schoolController.text, equals('SMPN 3 Cibinong'));
      expect(notified, isTrue);
    });

    test('isValid returns false when schoolDestination is empty', () {
      controller.schoolController.text = '   ';
      expect(controller.isValid, isFalse);
    });

    test('getBatchData packages current operational batch parameters into model', () {
      final batchData = controller.getBatchData();

      expect(batchData.batchCode, equals('MBG-2026-001'));
      expect(batchData.targetAkg.groupName, equals('SD Kelas 4 – 6 (10 – 12 Tahun)'));
      expect(batchData.sppgUnit, equals(AppStrings.defaultSppgUnit));
      expect(batchData.schoolDestination, equals(AppStrings.defaultSchoolDestination));
      expect(batchData.notes, equals(AppStrings.defaultInspectionNotes));
    });

    test('proceedToStep2 fails validation if destination is empty', () async {
      controller.schoolController.text = '';

      final success = await controller.proceedToStep2();

      expect(success, isFalse);
      expect(controller.errorMessage, isNotNull);
      expect(controller.isLoading, isFalse);
    });

    test('proceedToStep2 succeeds when inputs are valid', () async {
      final success = await controller.proceedToStep2();

      expect(success, isTrue);
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });
  });

  group('MenuInspectionScreen Widget Tests', () {
    testWidgets('Renders all visual components matching 05 - Input Data Batch & Periksa Menu.png', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MenuInspectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // App bar with progress
      expect(find.byType(StepProgressAppBar), findsOneWidget);
      expect(find.text(AppStrings.inspectionTitle), findsOneWidget);
      expect(find.text(AppStrings.step1Of4), findsOneWidget);

      // Section title & definition banner
      expect(find.text(AppStrings.batchInfoSectionTitle), findsOneWidget);
      expect(find.byType(BatchDefinitionBanner), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText().contains('Definisi Batch:'),
        ),
        findsOneWidget,
      );

      // Locked batch fields
      expect(find.byType(LockedBatchField), findsNWidgets(2));
      expect(find.text(AppStrings.batchCodeLabel), findsOneWidget);
      expect(find.text('MBG-2026-001'), findsOneWidget);
      expect(find.text(AppStrings.rfidSyncedBadge), findsOneWidget);

      // Target demographic selector & AKG indicator
      expect(find.byType(TargetGroupSelector), findsOneWidget);
      expect(find.text(AppStrings.targetGroupLabel), findsOneWidget);
      expect(find.text(AppStrings.btnUbahAkg), findsOneWidget);
      expect(find.text('SD Kelas 4 – 6 (10 – 12 Tahun)'), findsOneWidget);
      expect(find.text('620 kkal • Protein 18–22g'), findsOneWidget);

      // SPPG Unit
      expect(find.text(AppStrings.sppgUnitLabel), findsOneWidget);
      expect(find.text(AppStrings.defaultSppgUnit), findsOneWidget);
      expect(find.text(AppStrings.lockedAutoBadge), findsOneWidget);

      // School destination input
      expect(find.text(AppStrings.schoolDestinationLabel), findsOneWidget);
      expect(find.text(AppStrings.defaultSchoolDestination), findsOneWidget);

      // Inspection notes
      expect(find.text(AppStrings.inspectionNotesLabel), findsOneWidget);
      expect(find.text(AppStrings.optionalBadge), findsOneWidget);

      // Standard notice and submit button
      expect(find.text(AppStrings.juknisVerificationNotice), findsOneWidget);
      expect(find.text(AppStrings.btnContinueToUniformity), findsOneWidget);
      expect(find.text(AppStrings.aiCameraActiveStep2Notice), findsOneWidget);
    });

    testWidgets('Tapping Ubah AKG opens bottom sheet modal and updates demographic', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MenuInspectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Ubah AKG"
      final ubahAkgButton = find.text(AppStrings.btnUbahAkg);
      expect(ubahAkgButton, findsOneWidget);
      await tester.tap(ubahAkgButton);
      await tester.pumpAndSettle();

      // Verify modal bottom sheet opened
      expect(find.text('Pilih Kelompok Penerima Sasaran'), findsOneWidget);
      expect(find.text('SMA / SMK (16 – 18 Tahun)'), findsOneWidget);

      // Tap on SMA / SMK option
      await tester.tap(find.text('SMA / SMK (16 – 18 Tahun)'));
      await tester.pumpAndSettle();

      // Verify modal closed and indicator updated
      expect(find.text('Pilih Kelompok Penerima Sasaran'), findsNothing);
      expect(find.text('SMA / SMK (16 – 18 Tahun)'), findsOneWidget);
      expect(find.text('780 kkal • Protein 25–30g'), findsOneWidget);
    });

    testWidgets('Tapping help icon on StepProgressAppBar opens help modal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MenuInspectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap help icon
      final helpIcon = find.byIcon(Icons.help_outline_rounded);
      expect(helpIcon, findsOneWidget);
      await tester.tap(helpIcon);
      await tester.pumpAndSettle();

      // Help modal visible
      expect(find.text(AppStrings.inspectionHelpTitle), findsOneWidget);
      expect(find.text('Mengerti'), findsOneWidget);

      // Dismiss help modal
      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.inspectionHelpTitle), findsNothing);
    });

    testWidgets('Submitting valid form triggers confirmation snackbar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: MenuInspectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to continue button if needed and tap
      final continueBtn = find.text(AppStrings.btnContinueToUniformity);
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verify feedback snackbar is displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Batch #MBG-2026-001 tersimpan'), findsOneWidget);
    });
  });
}
