import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../models/nutrition_analysis_model.dart';

class NutritionProgressCard extends StatelessWidget {
  final NutrientMetricModel metric;

  const NutritionProgressCard({
    super.key,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (metric.currentValue / metric.targetValue).clamp(0.0, 1.0);
    final isSurplus = metric.isSurplus;
    final primaryBarColor = isSurplus ? const Color(0xFFD97706) : const Color(0xFF163E32);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isSurplus ? const Color(0xFFD97706) : const Color(0xFF1E6C45),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  metric.name,
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 14.5,
                    color: const Color(0xFF64748B),
                  ),
                  children: [
                    TextSpan(
                      text: metric.currentValue % 1 == 0
                          ? metric.currentValue.toInt().toString()
                          : metric.currentValue.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isSurplus ? const Color(0xFFDC2626) : AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: ' / ${metric.targetValue} ${metric.unit}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE5EDE3),
              valueColor: AlwaysStoppedAnimation<Color>(primaryBarColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${metric.percentageOfTarget}% Target${isSurplus ? ' (Surplus Lemak)' : ''}',
                style: AppTypography.captionBold.copyWith(
                  fontSize: 12,
                  color: isSurplus ? const Color(0xFFB45309) : const Color(0xFF53675C),
                ),
              ),
              const Spacer(),
              if (isSurplus) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFFDE68A),
                      width: 1.0,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 12,
                        color: Color(0xFFB45309),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Di atas Target',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 13,
                      color: Color(0xFF15803D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      metric.statusLabel,
                      style: AppTypography.captionBold.copyWith(
                        fontSize: 11.5,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
