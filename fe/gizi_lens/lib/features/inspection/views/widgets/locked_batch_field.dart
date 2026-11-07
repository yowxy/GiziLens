import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

/// Reusable read-only locked parameter field for batch metadata.
class LockedBatchField extends StatelessWidget {
  final String label;
  final Widget? trailingHeader;
  final Widget leading;
  final String value;
  final TextStyle? valueStyle;

  const LockedBatchField({
    super.key,
    required this.label,
    this.trailingHeader,
    required this.leading,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            if (trailingHeader != null) ...[
              const SizedBox(width: 8),
              Flexible(child: trailingHeader!),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderMedium,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: valueStyle ??
                      AppTypography.bodyMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: Color(0xFF7E9186),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
