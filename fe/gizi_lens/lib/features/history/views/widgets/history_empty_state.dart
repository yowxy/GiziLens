import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';

// Empty state placeholder displaying mascot Lensy with magnifying glass
class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppAssets.mascotLensy,
              width: 175,
              height: 175,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.emptyHistoryTitle,
              textAlign: TextAlign.center,
              style: AppTypography.h2.copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F261E),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
