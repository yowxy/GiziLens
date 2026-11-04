import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';

/// Reusable pill badge indicating official BGN / SPPG portal status.
class OfficialPortalBadge extends StatelessWidget {
  final String label;

  const OfficialPortalBadge({
    super.key,
    this.label = AppStrings.portalResmiBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.portalBadgeBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFD2E0D4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 14,
            color: AppColors.portalBadgeText,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTypography.badge.copyWith(
                color: AppColors.portalBadgeText,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
