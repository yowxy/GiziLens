import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';

class NutrientChipsRow extends StatelessWidget {
  const NutrientChipsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NutrientItem(
        label: AppStrings.nutrientPokok,
        icon: Icons.bakery_dining_outlined,
      ),
      _NutrientItem(
        label: AppStrings.nutrientLauk,
        icon: Icons.egg_outlined,
      ),
      _NutrientItem(
        label: AppStrings.nutrientSayur,
        icon: Icons.eco_outlined,
      ),
      _NutrientItem(
        label: AppStrings.nutrientBuah,
        icon: Icons.apple_outlined,
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NutrientItem {
  final String label;
  final IconData icon;

  _NutrientItem({
    required this.label,
    required this.icon,
  });
}
