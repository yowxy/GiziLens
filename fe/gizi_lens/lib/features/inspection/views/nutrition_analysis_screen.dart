import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../controllers/nutrition_analysis_controller.dart';
import 'widgets/nutrition_progress_card.dart';
import 'widgets/step_progress_app_bar.dart';

class NutritionAnalysisScreen extends StatefulWidget {
  const NutritionAnalysisScreen({super.key});

  @override
  State<NutritionAnalysisScreen> createState() => _NutritionAnalysisScreenState();
}

class _NutritionAnalysisScreenState extends State<NutritionAnalysisScreen> {
  late final NutritionAnalysisController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NutritionAnalysisController();
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
    final success = await _controller.proceedToStepConfirmation();
    if (success && mounted) {
      try {
        context.push(RouteNames.auditConfirmation);
      } catch (_) {
        context.go(RouteNames.auditConfirmation);
      }
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.componentDetection);
    }
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
              'Standar 5 Pilar Nutrisi MBG',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Penilaian AKG mencakup Energi Total, Protein Hewani & Nabati, Lemak Sehat, Karbohidrat Kompleks, dan Serat/Vitamin. Ambang batas deviasi toleransi yang diizinkan adalah ±10% dari target gizi sasaran usia sekolah.',
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
          subtitle: AppStrings.step4Of4,
          currentStep: 4,
          totalSteps: 4,
          onBack: _handleBack,
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
                    _buildTargetSasaranCard(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.bar_chart_rounded,
                          size: 19,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.summary5PillarsTitle,
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
                            AppStrings.tolerancePill,
                            style: AppTypography.captionBold.copyWith(
                              fontSize: 11.5,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE2ECE0),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A0F261E),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < _controller.metrics.length; i++) ...[
                            NutritionProgressCard(
                              metric: _controller.metrics[i],
                            ),
                            if (i < _controller.metrics.length - 1)
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFEDF2E8),
                              ),
                          ],
                        ],
                      ),
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
                              AppStrings.btnViewRecommendations,
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
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
                      onPressed: _handleBack,
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
                            Icons.undo_rounded,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.btnBackToComponents,
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

  Widget _buildTargetSasaranCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2ECE0),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F261E),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF2E3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.school_outlined,
                    size: 20,
                    color: Color(0xFF1E6C45),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.targetAudienceTitle,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5EE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  AppStrings.targetAgePill,
                  style: AppTypography.captionBold.copyWith(
                    fontSize: 11.5,
                    color: const Color(0xFF53675C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.targetAkgDescription,
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFF334155),
              height: 1.5,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.targetNutritionDisclaimer,
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
