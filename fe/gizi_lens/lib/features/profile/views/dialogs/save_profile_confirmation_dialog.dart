import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/modal_card_dialog.dart';

class SaveProfileConfirmationDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const SaveProfileConfirmationDialog({
    super.key,
    this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onConfirmSave,
  }) {
    return ModalCardDialog.show<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SaveProfileConfirmationDialog(
        onConfirm: () {
          Navigator.of(ctx).pop(true);
          onConfirmSave?.call();
        },
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalCardDialog(
      backgroundColor: const Color(0xFFFAF9F4),
      showCloseButton: false,
      topBadge: _buildIconBadge(),
      title: AppStrings.saveProfileDialogTitle,
      subtitle: AppStrings.saveProfileDialogSubtitle,
      customContent: _buildInfoCard(),
      primaryButtonText: AppStrings.saveProfileDialogConfirmBtn,
      primaryButtonColor: AppColors.primaryDeep,
      primaryButtonTextColor: Colors.white,
      primaryButtonIcon: Icons.check_rounded,
      primaryButtonIconColor: AppColors.accentGold,
      onPrimaryPressed: onConfirm,
      secondaryButtonText: AppStrings.saveProfileDialogCancelBtn,
      onSecondaryPressed: onCancel,
    );
  }

  Widget _buildIconBadge() {
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.dialogSageBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD4E5DA),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.how_to_reg_rounded,
                size: 34,
                color: AppColors.primaryDeep,
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 2,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.dialogAccentRing,
                  width: 2.4,
                ),
                color: const Color(0xFFFAF9F4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dialogInfoBoxBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.dialogInfoBoxBorder,
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.schedule_rounded,
              size: 18,
              color: AppColors.primaryMedium,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF335C49),
                  height: 1.45,
                ),
                children: [
                  const TextSpan(text: AppStrings.saveProfileDialogInfo),
                  TextSpan(
                    text: AppStrings.saveProfileDialogInfoBold,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
