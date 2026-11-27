import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/services/backend_api_service.dart';
import '../models/payment_order_model.dart';
import '../models/pricing_plan_model.dart';

/// Midtrans Snap integration.
///
/// All gateway calls go through the backend (`/api/v1/payment/*`) so the
/// `MIDTRANS_SERVER_KEY` never ships inside the app. The app only opens the
/// Snap redirect URL and then asks the backend for the authoritative status.
///
/// When the backend has no server key configured (local development) it answers
/// with `mode = sandbox_simulator`. Debug builds accept that and fall back to a
/// deterministic local order so the UI can still be exercised; release builds
/// refuse to fake a payment.
class MidtransSandboxService {
  MidtransSandboxService._();
  static final MidtransSandboxService instance = MidtransSandboxService._();

  /// Maps GiziLens [PaymentMethodOption] to Midtrans Snap `enabled_payments`.
  static List<String> enabledPaymentsFor(PaymentMethodOption method) {
    return switch (method.type) {
      PaymentMethodType.qris => ['gopay', 'shopeepay', 'other_qris'],
      PaymentMethodType.bankTransfer => switch (method.bankCode) {
          'mandiri' => ['echannel'],
          'bca' => ['bca_va'],
          'bri' => ['bri_va'],
          'bni' => ['bni_va'],
          _ => ['bca_va'],
        },
      PaymentMethodType.creditCard => ['credit_card'],
    };
  }

  /// Creates a Snap transaction for the selected plan.
  Future<PaymentOrderModel> createOrder({
    required PricingPlanModel plan,
    required PaymentMethodOption method,
    required String officerName,
    required String officerEmail,
    required String sppgUnit,
  }) async {
    final safeName = officerName.trim().isEmpty || officerName == '-'
        ? 'Petugas SPPG'
        : officerName.trim();
    final safeEmail = officerEmail.trim().isEmpty
        ? 'petugas.sppg@gizilens.id'
        : officerEmail.trim();

    final baseOrder = PaymentOrderModel.create(
      planId: plan.id,
      planName: plan.name,
      planPrice: plan.billedPrice,
      method: method,
      officerName: safeName,
      sppgUnit: sppgUnit,
    );

    Map<String, dynamic>? backendResp;
    try {
      backendResp = await BackendApiService.instance.createMidtransTransaction({
        'order_id': baseOrder.orderId,
        'plan_id': plan.id,
        'plan_name': plan.name,
        'gross_amount': baseOrder.totalAmount,
        'customer_name': safeName,
        'customer_email': safeEmail,
        'payment_method': method.id,
      });
    } catch (error) {
      debugPrint('Midtrans backend tidak tersedia: $error');
    }

    if (backendResp != null) {
      final mode = (backendResp['mode'] as String? ?? '').toLowerCase();
      final snapToken = backendResp['snap_token'] as String?;
      final redirectUrl = backendResp['redirect_url'] as String?;
      if (mode.startsWith('midtrans_') &&
          ((snapToken != null && snapToken.isNotEmpty) ||
              (redirectUrl != null && redirectUrl.isNotEmpty))) {
        return baseOrder.copyWith(
          snapToken: snapToken,
          redirectUrl: redirectUrl ?? baseOrder.redirectUrl,
          isLiveSandboxApi: true,
          isProductionGateway: mode == 'midtrans_production',
        );
      }
    }

    if (kReleaseMode) {
      throw StateError(
        'Gateway pembayaran belum tersedia. Hubungi admin GiziLens.',
      );
    }

    // Debug-only simulator so the checkout UI stays usable without credentials.
    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint(
      'Midtrans simulator: ${baseOrder.orderId} untuk ${plan.name} - Rp ${baseOrder.totalAmount} via ${method.name}',
    );
    return baseOrder;
  }

  /// Asks the backend for the authoritative Midtrans transaction status.
  Future<PaymentStatus> checkTransactionStatus(PaymentOrderModel order) async {
    try {
      final backendResp = await BackendApiService.instance.checkMidtransStatus(
        order.orderId,
      );
      if (backendResp != null) {
        final txStatus =
            (backendResp['transaction_status'] as String? ?? '').toLowerCase();
        if (txStatus.isNotEmpty) return _parseMidtransStatus(txStatus);
      }
    } catch (error) {
      debugPrint('Gagal memeriksa status Midtrans: $error');
    }
    return order.status;
  }

  static PaymentStatus _parseMidtransStatus(String txStatus) {
    return switch (txStatus) {
      'settlement' || 'capture' => PaymentStatus.settlement,
      'expire' => PaymentStatus.expired,
      'deny' || 'cancel' || 'failure' => PaymentStatus.failed,
      _ => PaymentStatus.pending,
    };
  }

  /// Debug-only: pretends the payment settled so the UI can be tested offline.
  Future<PaymentOrderModel> simulatePaymentSettlement(
    PaymentOrderModel order,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return order.copyWith(status: PaymentStatus.settlement);
  }

  /// Currency formatting helper (e.g. Rp 299.000)
  static String formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }
}
