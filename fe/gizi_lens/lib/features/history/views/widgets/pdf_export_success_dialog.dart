import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/modal_card_dialog.dart';

/// Success dialog shown after exporting the audit PDF, matching "popup.png".
class PdfExportSuccessDialog extends StatelessWidget {
  const PdfExportSuccessDialog({
    super.key,
    required this.auditId,
    required this.onBackToHome,
  });

  final String auditId;
  final VoidCallback onBackToHome;

  static Future<void> show(
    BuildContext context, {
    required String auditId,
    required VoidCallback onBackToHome,
  }) {
    return ModalCardDialog.show<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => PdfExportSuccessDialog(
        auditId: auditId,
        onBackToHome: () {
          Navigator.of(dialogCtx).pop();
          onBackToHome();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedId = auditId.trim().isEmpty
        ? '#MBG-AUDIT'
        : (auditId.trim().startsWith('#') ? auditId.trim() : '#${auditId.trim()}');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      elevation: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6F0),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE6E8DF),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F0F261E),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSuccessBadge(),
                const SizedBox(height: 20),
                Text(
                  'PDF Berhasil dibuat!',
                  textAlign: TextAlign.center,
                  style: AppTypography.h2.copyWith(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'ID Audit: '),
                      TextSpan(
                        text: normalizedId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const TextSpan(
                        text: '  telah\nterkunci di server sentral',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onBackToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDeep,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Kembali ke Beranda',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 19,
                          color: Color(0xFFD6943C),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBadge() {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFEBF3EA),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: Color(0xFFD6E8D7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 32,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 6,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFCA933E),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 4.5,
                      height: 4.5,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
