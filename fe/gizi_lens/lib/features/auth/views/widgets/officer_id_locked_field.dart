import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';

/// Read-only locked field displaying verified SPPG officer registration code.
class OfficerIdLockedField extends StatelessWidget {
  final String officerId;

  const OfficerIdLockedField({
    super.key,
    this.officerId = AppStrings.defaultOfficerIdValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label Header with BGN Verification Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.officerIdLabel,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.verifiedBgnBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 13,
                    color: AppColors.verifiedBgnText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppStrings.verifiedBgnTag,
                    style: AppTypography.captionBold.copyWith(
                      color: AppColors.verifiedBgnText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Locked Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.inputLockedBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.infoCardBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.iconFieldMuted,
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '123',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.iconFieldMuted,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  officerId,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 1.2,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
              const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.officerIdHelperText,
          style: AppTypography.caption.copyWith(
            fontSize: 11,
            color: AppColors.textMuted,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
