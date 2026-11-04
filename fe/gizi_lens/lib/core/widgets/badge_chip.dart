import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class BadgeChip extends StatelessWidget {
  final String label;
  final Widget? icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final TextStyle? textStyle;

  const BadgeChip({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor = AppColors.badgeBg,
    this.textColor = AppColors.badgeText,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    this.borderRadius = 999,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null ? Border.all(color: borderColor!, width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle ??
                  AppTypography.badge.copyWith(
                    color: textColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
