import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';

class FoodPartitionView extends StatelessWidget {
  const FoodPartitionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.grid_view_rounded,
              size: 16,
              color: Color(0xFF53675C),
            ),
            const SizedBox(width: 6),
            Text(
              AppStrings.compartmentViewTitle,
              style: AppTypography.captionBold.copyWith(
                fontSize: 12,
                color: const Color(0xFF53675C),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFDCE6DA),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                AppAssets.omprengBakiSample,
                fit: BoxFit.cover,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
