import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/services/inspection_session_service.dart';
import '../controllers/component_detection_controller.dart';
import '../models/food_component_model.dart';
import 'widgets/detected_component_card.dart';
import 'widgets/food_partition_view.dart';
import 'widgets/segmentation_process_card.dart';
import 'widgets/step_progress_app_bar.dart';

class ComponentDetectionScreen extends StatefulWidget {
  const ComponentDetectionScreen({super.key});

  @override
  State<ComponentDetectionScreen> createState() => _ComponentDetectionScreenState();
}

class _ComponentDetectionScreenState extends State<ComponentDetectionScreen> {
  late final ComponentDetectionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ComponentDetectionController();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final success = await _controller.proceedToStep4();
    if (success && mounted) {
      try {
        context.push(RouteNames.nutritionAnalysis);
      } catch (_) {
        context.go(RouteNames.nutritionAnalysis);
      }
    }
  }

  void _handleRetake() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.scanOmpreng);
    }
  }

  void _showEditComponentModal(FoodComponentModel item) {
    final nameController = TextEditingController(text: item.name);
    final gramController = TextEditingController(text: item.estimatedGram.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          int currentGram = int.tryParse(gramController.text) ?? item.estimatedGram;

          void updateGram(int delta) {
            final next = (currentGram + delta).clamp(10, 1000);
            gramController.text = next.toString();
            setModalState(() {
              currentGram = next;
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6F1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.iconData,
                          size: 20,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Koreksi Porsi Komponen',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(sheetCtx),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Perbarui nama makanan atau sesuaikan gramatur porsi hasil segmentasi AI baki ompreng.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Bahan / Komponen Makanan',
                      labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.restaurant_menu_rounded, size: 20, color: AppColors.primaryDeep),
                      filled: true,
                      fillColor: const Color(0xFFF8FAF7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2ECE0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: gramController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setModalState(() {
                        currentGram = int.tryParse(val) ?? currentGram;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Gramatur Bersih Porsi (gram)',
                      suffixText: 'gram',
                      labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.scale_outlined, size: 20, color: AppColors.primaryDeep),
                      filled: true,
                      fillColor: const Color(0xFFF8FAF7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2ECE0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('-25g'),
                        onPressed: () => updateGram(-25),
                      ),
                      ActionChip(
                        label: const Text('-10g'),
                        onPressed: () => updateGram(-10),
                      ),
                      ActionChip(
                        label: const Text('+10g'),
                        onPressed: () => updateGram(10),
                      ),
                      ActionChip(
                        label: const Text('+25g'),
                        onPressed: () => updateGram(25),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final newName = nameController.text.trim();
                        final newGram = int.tryParse(gramController.text.trim()) ?? item.estimatedGram;
                        if (newName.isEmpty) return;

                        _controller.updateComponent(
                          id: item.id,
                          newName: newName,
                          newGram: newGram,
                        );

                        Navigator.pop(sheetCtx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Porsi "$newName" berhasil diperbarui menjadi $newGram gram.',
                              style: AppTypography.bodySmall.copyWith(color: Colors.white),
                            ),
                            backgroundColor: AppColors.primaryDeep,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDeep,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Simpan Koreksi', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Deteksi & Segmentasi AI',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'AI telah melakukan segmentasi otomatis terhadap baki saji ompreng 5 sekat dan mencocokkan setiap porsi makanan dengan basis data nutrisi nasional BGN. Anda dapat memverifikasi atau mengoreksi gramatur sebelum kalkulasi gizi akhir.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDeep,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Mengerti', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundSplash,
        appBar: StepProgressAppBar(
          title: AppStrings.inspectionTitle,
          subtitle: AppStrings.step3Of4,
          currentStep: 3,
          totalSteps: 4,
          onBack: _handleRetake,
          onHelpTap: _showHelp,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SegmentationProcessCard(),
                    const SizedBox(height: 18),
                    FoodPartitionView(
                      photoBytes: InspectionSessionService.instance.capturedPhoto,
                      aspectRatio: InspectionSessionService.instance.capturedPhotoAspectRatio,
                      components: _controller.components,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.detectedComponentsTitle,
                            style: AppTypography.titleLarge.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAEFE7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_controller.components.length} Bahan',
                            style: AppTypography.captionBold.copyWith(
                              fontSize: 11.5,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final item in _controller.components)
                      DetectedComponentCard(
                        component: item,
                        onTap: () => _showEditComponentModal(item),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE4E9E0),
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _controller.isLoading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDeep,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_controller.isLoading) ...[
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ] else ...[
                            Text(
                              AppStrings.btnCheckAndCorrect,
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _handleRetake,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        side: const BorderSide(
                          color: Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.btnRetakePhoto,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
