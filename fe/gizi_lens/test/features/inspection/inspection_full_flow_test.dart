import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/features/inspection/controllers/component_detection_controller.dart';
import 'package:gizi_lens/features/inspection/controllers/nutrition_analysis_controller.dart';
import 'package:gizi_lens/features/inspection/controllers/scan_ompreng_controller.dart';
import 'package:gizi_lens/features/inspection/views/audit_confirmation_screen.dart';
import 'package:gizi_lens/features/inspection/views/component_detection_screen.dart';
import 'package:gizi_lens/features/inspection/views/nutrition_analysis_screen.dart';
import 'package:gizi_lens/features/inspection/views/scan_ompreng_screen.dart';
import 'package:gizi_lens/features/inspection/views/widgets/google_lens_hologram_scanner.dart';
import 'package:gizi_lens/features/inspection/views/widgets/scan_validation_card.dart';

void main() {
  group('Inspection Controllers Unit Tests', () {
    test('ScanOmprengController initial states and toggles', () {
      final controller = ScanOmprengController();
      expect(controller.isFlashOn, isFalse);
      expect(controller.isAnalyzing, isFalse);
      expect(controller.isLightingOk, isTrue);
      expect(controller.showAiBoundingBoxes, isTrue);

      controller.toggleFlash();
      expect(controller.isFlashOn, isTrue);

      controller.toggleBoundingBoxes();
      expect(controller.showAiBoundingBoxes, isFalse);
    });

    test('ComponentDetectionController manages 5 food items and gram updates', () {
      final controller = ComponentDetectionController();
      expect(controller.totalIngredients, equals(5));
      expect(controller.components.first.name, equals('Nasi Kuning'));

      controller.updateComponentGram('comp_1', 220);
      expect(controller.components.first.estimatedGram, equals(220));
    });

    test('NutritionAnalysisController loads 4 key pillars metrics', () {
      final controller = NutritionAnalysisController();
      expect(controller.metrics.length, equals(4));
      expect(controller.metrics[0].name, equals('Energi Total'));
      expect(controller.metrics[2].isSurplus, isTrue);
    });
  });

  group('Inspection Flow Widget Tests', () {
    testWidgets('ScanOmprengScreen renders viewfinder, hologram and validation card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ScanOmprengScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GoogleLensHologramScanner), findsOneWidget);
      expect(find.byType(ScanValidationCard), findsOneWidget);
      expect(find.text(AppStrings.step2Of4), findsOneWidget);
      expect(find.text(AppStrings.positionCameraPrompt), findsOneWidget);
    });

    testWidgets('ComponentDetectionScreen renders AI segmentation and components list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ComponentDetectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.step3Of4), findsOneWidget);
      expect(find.text(AppStrings.segmentationProcessTitle), findsOneWidget);
      expect(find.text(AppStrings.segmentationDone100), findsOneWidget);
      expect(find.text(AppStrings.compartmentViewTitle), findsOneWidget);
      expect(find.text(AppStrings.detectedComponentsTitle), findsOneWidget);
      expect(find.text('Nasi Kuning'), findsOneWidget);
      expect(find.text('Telur Rebus'), findsOneWidget);
      expect(find.text(AppStrings.btnCheckAndCorrect), findsOneWidget);
      expect(find.text(AppStrings.btnRetakePhoto), findsOneWidget);
    });

    testWidgets('NutritionAnalysisScreen renders 5 pillars metrics and recommendations', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: NutritionAnalysisScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.step4Of4), findsOneWidget);
      expect(find.text(AppStrings.targetAudienceTitle), findsOneWidget);
      expect(find.text(AppStrings.summary5PillarsTitle), findsOneWidget);
      expect(find.text('Energi Total'), findsOneWidget);
      expect(find.text('Protein Hewani & Nabati'), findsOneWidget);
      expect(find.text('Lemak Sehat'), findsOneWidget);
      expect(find.text('Karbohidrat Kompleks'), findsOneWidget);
      expect(find.text(AppStrings.btnViewRecommendations), findsOneWidget);
      expect(find.text(AppStrings.btnBackToComponents), findsOneWidget);
    });

    testWidgets('AuditConfirmationScreen renders protocol and verified portions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AuditConfirmationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.confirmationTitle), findsOneWidget);
      expect(find.text(AppStrings.confirmationSubtitle), findsOneWidget);
      expect(find.text(AppStrings.sppgBadgeCode), findsOneWidget);
      expect(find.text(AppStrings.finalStageTitle), findsOneWidget);
      expect(find.text(AppStrings.defaultSamplingBatchCode), findsOneWidget);
      expect(find.text(AppStrings.defaultSamplingSchool), findsOneWidget);
      expect(find.text(AppStrings.verifiedPortionsTitle), findsOneWidget);
      expect(find.text(AppStrings.btnSaveInspectionLock), findsOneWidget);
      expect(find.text(AppStrings.btnBackToInspection), findsOneWidget);
    });
  });
}
