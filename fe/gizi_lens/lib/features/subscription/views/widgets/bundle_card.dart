import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../models/pricing_plan_model.dart';
import '../../services/midtrans_sandbox_service.dart';

class BundleCard extends StatelessWidget {
  final PricingPlanModel plan;
  final bool isSelected;
  final VoidCallback onSelect;

  const BundleCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? plan.primaryColor : const Color(0xFFE2ECE0),
            width: isSelected ? 2.2 : 1.2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: plan.primaryColor.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, 6),
              )
            else
              const BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge if available
            if (plan.badgeText != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      plan.primaryColor,
                      plan.primaryColor.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      plan.badgeText!,
                      style: AppTypography.captionBold.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: plan.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          plan.icon,
                          size: 24,
                          color: plan.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: AppTypography.titleLarge.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              plan.tagline,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Radio selector circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? plan.primaryColor : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? plan.primaryColor
                                : const Color(0xFFCBD5E1),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Center(
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (plan.bundleHighlights.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: plan.bundleHighlights
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: plan.primaryColor.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: plan.primaryColor.withValues(alpha: 0.16),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: AppTypography.captionBold.copyWith(
                                  fontSize: 10.5,
                                  color: plan.primaryColor,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  const Divider(height: 1, color: Color(0xFFEEF3EC)),
                  const SizedBox(height: 16),

                  // Price Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        MidtransSandboxService.formatRupiah(plan.billedPrice),
                        style: AppTypography.h1.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '/${plan.billingPeriod}',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  if (plan.originalPrice != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          MidtransSandboxService.formatRupiah(plan.originalPrice!),
                          style: AppTypography.caption.copyWith(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Hemat ${plan.savingsPercentage}%',
                            style: AppTypography.captionBold.copyWith(
                              fontSize: 10.5,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Feature bullets
                  ...plan.features.map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 17,
                              color: isSelected
                                  ? plan.primaryColor
                                  : const Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature,
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: 12.5,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
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
