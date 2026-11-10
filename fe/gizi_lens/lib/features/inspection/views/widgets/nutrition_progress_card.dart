import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../models/nutrition_analysis_model.dart';

class NutritionProgressCard extends StatelessWidget {
  final NutrientMetricModel metric;

  const NutritionProgressCard({super.key, required this.metric});

  String _formatValue(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final progress = (metric.currentValue / metric.targetValue).clamp(0.0, 1.0);
    final isSurplus = metric.isSurplus;
    final accentColor = isSurplus
        ? const Color(0xFFD97706)
        : const Color(0xFF1E6C45);

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
                  color: accentColor,
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
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 14.5,
                      color: const Color(0xFF64748B),
                    ),
                    children: [
                      TextSpan(
                        text: _formatValue(metric.currentValue),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isSurplus
                              ? const Color(0xFFDC2626)
                              : AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' / ${_formatValue(metric.targetValue)} ${metric.unit}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${metric.percentageOfTarget}%',
                style: AppTypography.captionBold.copyWith(
                  fontSize: 12.5,
                  color: accentColor,
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
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isSurplus
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                size: 13,
                color: isSurplus
                    ? const Color(0xFFB45309)
                    : const Color(0xFF15803D),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  metric.statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionBold.copyWith(
                    fontSize: 11.5,
                    color: isSurplus
                        ? const Color(0xFFB45309)
                        : const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
