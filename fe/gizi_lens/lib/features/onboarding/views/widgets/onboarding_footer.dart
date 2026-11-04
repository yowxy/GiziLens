import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/page_indicator.dart';

class OnboardingFooter extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onNext;

  const OnboardingFooter({
    super.key,
    required this.currentIndex,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLastPage = currentIndex == 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PageIndicator(
            count: 2,
            currentIndex: currentIndex,
            activeColor: AppColors.primaryDark,
            inactiveColor: AppColors.borderMedium,
          ),
          const SizedBox(height: 20),
          AppButton(
            text: isLastPage ? AppStrings.btnMulaiSekarang : AppStrings.btnLanjutkan,
            onPressed: onNext,
            trailingIcon: isLastPage
                ? null
                : const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLastPage) ...[
                const Icon(
                  Icons.verified_outlined,
                  size: 14,
                  color: AppColors.accentGold,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                AppStrings.taglinePlain,
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
