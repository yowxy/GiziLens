import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_dot.dart';
import '../controllers/menu_inspection_controller.dart';
import 'widgets/batch_definition_banner.dart';
import 'widgets/locked_batch_field.dart';
import 'widgets/step_progress_app_bar.dart';
import 'widgets/target_group_selector.dart';

/// Step 1: Input Data Batch & Periksa Menu screen.
class MenuInspectionScreen extends StatefulWidget {
  const MenuInspectionScreen({super.key});

  @override
  State<MenuInspectionScreen> createState() => _MenuInspectionScreenState();
}

class _MenuInspectionScreenState extends State<MenuInspectionScreen> {
  late final MenuInspectionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MenuInspectionController();
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

  void _showHelpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.primaryDeep,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.inspectionHelpTitle,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.inspectionHelpContent,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDeep,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Mengerti',
                    style: AppTypography.button.copyWith(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    FocusScope.of(context).unfocus();

    final success = await _controller.proceedToStep2();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Batch #${_controller.batchCode} tersimpan. Menyiapkan kamera AI untuk Langkah 2...',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryDeep,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      try {
        context.push(RouteNames.scanOmpreng);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSplash,
      appBar: StepProgressAppBar(
        title: AppStrings.inspectionTitle,
        subtitle: AppStrings.step1Of4,
        currentStep: 1,
        totalSteps: 4,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RouteNames.dashboard);
          }
        },
        onHelpTap: _showHelpModal,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenHorizontalPadding,
              vertical: 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.batchInfoSectionTitle,
                      style: AppTypography.h1.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const BatchDefinitionBanner(),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.borderLight,
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LockedBatchField(
                            label: AppStrings.batchCodeLabel,
                            trailingHeader: Text(
                              AppStrings.rfidSyncedBadge,
                              style: AppTypography.caption.copyWith(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            leading: const Text(
                              '#',
                              style: TextStyle(
                                fontSize: 17,
                                color: Color(0xFF6B7F73),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            value: _controller.batchCode,
                            valueStyle: AppTypography.titleSmall.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TargetGroupSelector(
                            selectedTargetAkg: _controller.selectedTargetAkg,
                            onTargetAkgChanged: _controller.selectTargetAkg,
                          ),
                          const SizedBox(height: 16),
                          LockedBatchField(
                            label: AppStrings.sppgUnitLabel,
                            trailingHeader: Text(
                              AppStrings.lockedAutoBadge,
                              style: AppTypography.caption.copyWith(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            leading: const Icon(
                              Icons.apartment_outlined,
                              size: 20,
                              color: Color(0xFF6B7F73),
                            ),
                            value: _controller.sppgUnit,
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.schoolDestinationLabel,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _controller.schoolController,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: AppStrings.schoolDestinationHint,
                                  hintStyle: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textLight,
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 13,
                                  ),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10),
                                    child: Icon(
                                      Icons.school_outlined,
                                      size: 20,
                                      color: Color(0xFF6B7F73),
                                    ),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 42,
                                    minHeight: 42,
                                  ),
                                  suffixIcon: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: Color(0xFF6B7F73),
                                    ),
                                  ),
                                  suffixIconConstraints: const BoxConstraints(
                                    minWidth: 42,
                                    minHeight: 42,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.borderMedium,
                                      width: 1.0,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.borderMedium,
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryDeep,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      AppStrings.inspectionNotesLabel,
                                      style: AppTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppStrings.optionalBadge,
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 11.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _controller.notesController,
                                minLines: 3,
                                maxLines: 5,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 13.5,
                                  color: const Color(0xFF2C3E35),
                                  height: 1.45,
                                ),
                                decoration: InputDecoration(
                                  hintText: AppStrings.inspectionNotesHint,
                                  hintStyle: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textLight,
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.all(14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.borderMedium,
                                      width: 1.0,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.borderMedium,
                                      width: 1.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryDeep,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        AppStrings.juknisVerificationNotice,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      text: AppStrings.btnContinueToUniformity,
                      backgroundColor: AppColors.primaryDeep,
                      height: 52,
                      borderRadius: 14,
                      isLoading: _controller.isLoading,
                      trailingIcon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: _handleContinue,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const StatusDot(
                          color: AppColors.accentCheckGreen,
                          size: 6,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppStrings.aiCameraActiveStep2Notice,
                            style: AppTypography.caption.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
