import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import 'profile_menu_item.dart';

class ProfileMenuSection extends StatelessWidget {
  final IconData headerIcon;
  final Color headerIconColor;
  final String title;
  final String? trailingText;
  final List<ProfileMenuItem> items;

  const ProfileMenuSection({
    super.key,
    required this.headerIcon,
    this.headerIconColor = AppColors.primaryDeep,
    required this.title,
    this.trailingText,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(
                headerIcon,
                size: 19,
                color: headerIconColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE2ECE0),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F261E),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.profileDivider,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
