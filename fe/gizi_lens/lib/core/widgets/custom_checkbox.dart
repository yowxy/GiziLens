import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable clean custom checkbox component with rounded corners and micro-interaction.
class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;
  final double borderRadius;
  final Color activeColor;
  final Color checkColor;
  final Color borderColor;

  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 18.0,
    this.borderRadius = 5.0,
    this.activeColor = AppColors.primaryDeep,
    this.checkColor = Colors.white,
    this.borderColor = AppColors.borderMedium,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: value ? activeColor : borderColor,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: value
            ? Icon(
                Icons.check_rounded,
                size: size * 0.78,
                color: checkColor,
              )
            : null,
      ),
    );
  }
}
