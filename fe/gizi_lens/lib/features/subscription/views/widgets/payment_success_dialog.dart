import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../../models/payment_order_model.dart';
import '../../services/midtrans_sandbox_service.dart';

class PaymentSuccessDialog extends StatelessWidget {
  final PaymentOrderModel order;

  const PaymentSuccessDialog({
    super.key,
    required this.order,
  });

  static Future<void> show(BuildContext context, PaymentOrderModel order) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PaymentSuccessDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = MidtransSandboxService.formatRupiah(order.totalAmount);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Success Icon
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF2E3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFBCE3C6),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF1E6C45),
                  size: 46,
                ),
              ),
              const SizedBox(height: 18),

              Text(
                'Pembayaran Berhasil!',
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'MIDTRANS SANDBOX SETTLEMENT',
                  style: AppTypography.captionBold.copyWith(
                    color: const Color(0xFF1E6C45),
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Selamat! Akun SPPG Anda kini berstatus Premium. Seluruh batasan kuota audit ompreng dan ekspor laporan resmi telah dibuka.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Receipt Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow('Order ID', order.orderId),
                    const Divider(height: 16, color: Color(0xFFE6EBE2)),
                    _buildReceiptRow('Paket', order.planName),
                    const Divider(height: 16, color: Color(0xFFE6EBE2)),
                    _buildReceiptRow('Metode', order.selectedMethod.name),
                    const Divider(height: 16, color: Color(0xFFE6EBE2)),
                    _buildReceiptRow('Status', 'LUNAS (Berhasil)', isStatus: true),
                    const Divider(height: 16, color: Color(0xFFE6EBE2)),
                    _buildReceiptRow('Total Dibayar', currencyFormat, isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action CTA
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // Close dialog then navigate to Dashboard and clear pricing/checkout stack
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.go(RouteNames.dashboard);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryForest,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Mulai Audit Premium Sekarang',
                    style: AppTypography.button.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isStatus = false,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 11.5,
          ),
        ),
        if (isStatus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFDDF2E3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: AppTypography.captionBold.copyWith(
                color: const Color(0xFF1E6C45),
                fontSize: 11,
              ),
            ),
          )
        else
          Flexible(
            child: Text(
              value,
              style: AppTypography.titleSmall.copyWith(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: isBold ? AppColors.primaryForest : AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
