import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';

/// Reusable informational callout banner defining operational batch standard.
class BatchDefinitionBanner extends StatelessWidget {
  const BatchDefinitionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4EC),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(
            color: AppColors.primaryDeep,
            width: 4.0,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: AppColors.primaryDeep,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12.5,
                  height: 1.45,
                  color: const Color(0xFF2C3E35),
                ),
                children: const [
                  TextSpan(
                    text: AppStrings.batchDefinitionPrefix,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: AppStrings.batchDefinitionDesc,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
