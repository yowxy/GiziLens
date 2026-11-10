import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../models/food_component_model.dart';

class FoodPartitionView extends StatelessWidget {
  final Uint8List? photoBytes;
  final double aspectRatio;
  final List<FoodComponentModel> components;

  const FoodPartitionView({
    super.key,
    required this.photoBytes,
    required this.aspectRatio,
    required this.components,
  });

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
          child: photoBytes == null ? _buildPlaceholder() : _buildPhoto(photoBytes!),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return SizedBox(
      height: 250,
      child: Center(
        child: Text(
          'Foto hasil scan belum tersedia',
          style: AppTypography.bodySmall.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPhoto(Uint8List bytes) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(bytes, fit: BoxFit.fill, gaplessPlayback: true),
              for (final component in components)
                if (component.boundingBox != null)
                  ..._buildComponentOverlay(component, constraints),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildComponentOverlay(
    FoodComponentModel component,
    BoxConstraints constraints,
  ) {
    final box = component.boundingBox!;
    final left = box.left * constraints.maxWidth;
    final top = box.top * constraints.maxHeight;
    return [
      Positioned(
        left: left,
        top: top,
        width: box.width * constraints.maxWidth,
        height: box.height * constraints.maxHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryDeep, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      Positioned(
        left: left + 4,
        top: top + 4,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryDeep,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${component.name} | ${component.estimatedGram} g',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionBold.copyWith(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    ];
  }
}
