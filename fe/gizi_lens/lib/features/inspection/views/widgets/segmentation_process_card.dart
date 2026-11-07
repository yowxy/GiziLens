import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';

class SegmentationProcessCard extends StatelessWidget {
  const SegmentationProcessCard({super.key});

  @override
  Widget build(BuildContext context) {
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
              const Icon(
                Icons.psychology_rounded,
                size: 22,
                color: AppColors.primaryDeep,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.segmentationProcessTitle,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                AppStrings.segmentationDone100,
                style: AppTypography.captionBold.copyWith(
                  color: const Color(0xFF1E6C45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 1.0,
              minHeight: 5,
              backgroundColor: Color(0xFFE2EBE2),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E6C45)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildCheckPoint(AppStrings.segQualityVerified),
                    const SizedBox(height: 8),
                    _buildCheckPoint(AppStrings.segGrammageCalculated),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    _buildCheckPoint(AppStrings.seg4Compartments),
                    const SizedBox(height: 8),
                    _buildCheckPoint(AppStrings.segNutrientReady),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 15,
          color: Color(0xFF1E824C),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
