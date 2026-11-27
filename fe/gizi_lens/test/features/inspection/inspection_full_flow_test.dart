import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/core/services/inspection_session_service.dart';
import 'package:gizi_lens/features/inspection/controllers/component_detection_controller.dart';
import 'package:gizi_lens/features/inspection/controllers/nutrition_analysis_controller.dart';
import 'package:gizi_lens/features/inspection/controllers/scan_ompreng_controller.dart';
import 'package:gizi_lens/features/inspection/models/food_component_model.dart';
import 'package:gizi_lens/features/inspection/views/audit_confirmation_screen.dart';
import 'package:gizi_lens/features/inspection/views/component_detection_screen.dart';
import 'package:gizi_lens/features/inspection/views/nutrition_analysis_screen.dart';
import 'package:gizi_lens/features/inspection/views/scan_ompreng_screen.dart';
import 'package:gizi_lens/features/inspection/views/widgets/google_lens_hologram_scanner.dart';
import 'package:gizi_lens/features/inspection/views/widgets/scan_validation_card.dart';

List<FoodComponentModel> _sampleComponents() => const [
      FoodComponentModel(
        id: '1',
        name: 'Nasi Kuning',
        estimatedGram: 220,
        compartmentNumber: 1,
        category: 'Pokok',
        confidencePercentage: 95,
        isVerified: true,
        complianceStatus: 'Sesuai',
        iconData: Icons.rice_bowl_rounded,
        calories: 396,
        protein: 6.6,
        fat: 6.6,
        carbohydrate: 74.8,
        fiber: 1.76,
      ),
      FoodComponentModel(
        id: '2',
        name: 'Telur Rebus',
        estimatedGram: 60,
        compartmentNumber: 2,
        category: 'Lauk',
        confidencePercentage: 92,
        isVerified: true,
        complianceStatus: 'Sesuai',
        iconData: Icons.egg_rounded,
        calories: 92.4,
        protein: 7.44,
        fat: 6.48,
        carbohydrate: 0.42,
        fiber: 0,
      ),
      FoodComponentModel(
        id: '3',
        name: 'Tempe Orek',
        estimatedGram: 50,
        compartmentNumber: 3,
        category: 'Lauk',
        confidencePercentage: 89,
        isVerified: true,
        complianceStatus: 'Sesuai',
        iconData: Icons.restaurant_rounded,
        calories: 100.5,
        protein: 9.95,
        fat: 4.4,
        carbohydrate: 6.75,
        fiber: 0.7,
      ),
      FoodComponentModel(
        id: '4',
        name: 'Sayur Bayam',
        estimatedGram: 75,
        compartmentNumber: 4,
        category: 'Sayur',
        confidencePercentage: 90,
        isVerified: true,
        complianceStatus: 'Sesuai',
        iconData: Icons.eco_rounded,
        calories: 17.25,
        protein: 2.18,
        fat: 0.3,
        carbohydrate: 2.7,
        fiber: 1.65,
      ),
      FoodComponentModel(
        id: '5',
        name: 'Pisang Mas',
        estimatedGram: 100,
        compartmentNumber: 5,
        category: 'Buah',
        confidencePercentage: 94,
        isVerified: true,
        complianceStatus: 'Sesuai',
        iconData: Icons.apple_rounded,
        calories: 89,
        protein: 1.1,
        fat: 0.3,
        carbohydrate: 22.8,
        fiber: 2.6,
      ),
    ];

void main() {
  setUp(() {
    InspectionSessionService.instance.reset();
  });

  group('Inspection Controllers Unit Tests', () {
    test('ScanOmprengController initial states and toggles', () {
      final controller = ScanOmprengController();
      expect(controller.isFlashOn, isFalse);
      expect(controller.isAnalyzing, isFalse);
      expect(controller.isLightingOk, isFalse);
      expect(controller.showAiBoundingBoxes, isTrue);

      controller.setValidationStates(
        lighting: true,
        wholeTray: true,
        focused: true,
        withinFrame: true,
      );
      expect(controller.isLightingOk, isTrue);

      controller.toggleFlash();
      expect(controller.isFlashOn, isTrue);

      controller.toggleBoundingBoxes();
      expect(controller.showAiBoundingBoxes, isFalse);
    });

    test('ComponentDetectionController manages 5 food items and gram updates', () {
      InspectionSessionService.instance.components = _sampleComponents();
      final controller = ComponentDetectionController();
      addTearDown(controller.dispose);

      expect(controller.totalIngredients, equals(5));
      expect(controller.components.first.name, equals('Nasi Kuning'));
      expect(controller.components.first.estimatedGram, equals(220));

      controller.updateComponent(id: '1', newGram: 250);
      expect(controller.components.first.estimatedGram, equals(250));
    });

    test('NutritionAnalysisController loads 5 key pillars metrics', () {
      InspectionSessionService.instance.components = _sampleComponents();
      final controller = NutritionAnalysisController();
      expect(controller.metrics.length, equals(5));
      expect(controller.metrics[0].name, equals('Energi Total'));
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
      InspectionSessionService.instance.components = _sampleComponents();
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
      expect(find.text(AppStrings.btnContinueToAudit), findsOneWidget);
      expect(find.text(AppStrings.btnBackToComponents), findsOneWidget);
    });

    testWidgets('AuditConfirmationScreen renders protocol and verified portions', (tester) async {
      InspectionSessionService.instance.updateBatchConfig(
        batchCode: 'MBG-2026-001',
      );
      InspectionSessionService.instance.components = _sampleComponents();
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
      expect(find.text('MBG-2026-001'), findsOneWidget);
      expect(find.text(AppStrings.defaultSamplingSchool), findsOneWidget);
      expect(find.text(AppStrings.verifiedPortionsTitle), findsOneWidget);
      expect(find.text(AppStrings.btnSaveInspectionLock), findsOneWidget);
      expect(find.text(AppStrings.btnBackToInspection), findsOneWidget);
    });
  });
}
