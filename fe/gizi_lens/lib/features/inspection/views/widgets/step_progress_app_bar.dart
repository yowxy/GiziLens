import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

/// Reusable application bar with multi-step linear progress indicator.
class StepProgressAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback? onHelpTap;

  const StepProgressAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    this.onHelpTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep / totalSteps).clamp(0.0, 1.0);

    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                  onPressed: onBack,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleLarge.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onHelpTap != null)
                  IconButton(
                    icon: const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    onPressed: onHelpTap,
                  ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.progressTrack,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDeep),
            minHeight: 3.5,
          ),
        ],
      ),
    );
  }
}
