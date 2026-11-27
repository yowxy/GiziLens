import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/payment_order_model.dart';
import '../models/pricing_plan_model.dart';

/// Service managing Midtrans Payment Gateway interactions in Sandbox Mode.
///
/// Designed with dual operational modes:
/// 1. Live Midtrans Sandbox Snap API: When a real Sandbox `MIDTRANS_SERVER_KEY`
///    (from Midtrans Sandbox dashboard) is configured in `.env`, creates an
///    authentic Snap transaction token & redirect URL via `app.sandbox.midtrans.com`.
/// 2. Interactive Sandbox Simulator: When running offline, in tests, or with
///    placeholder credentials, simulates QRIS, Virtual Account, and Credit Card
///    flows deterministically without charging real funds.
class MidtransSandboxService {
  MidtransSandboxService._();
  static final MidtransSandboxService instance = MidtransSandboxService._();

  static const String _placeholderClientKey = 'SB-Mid-client-GiziLens2026';
  static const String _placeholderServerKey = 'SB-Mid-server-GiziLens2026';
  static const String sandboxSnapApiUrl =
      'https://app.sandbox.midtrans.com/snap/v1/transactions';
  static const String sandboxCoreApiBase = 'https://api.sandbox.midtrans.com/v2';

  String get clientKey {
    try {
      if (dotenv.isInitialized) {
        final key = dotenv.env['MIDTRANS_CLIENT_KEY']?.trim();
        if (key != null && key.isNotEmpty) return key;
      }
    } catch (_) {}
    return _placeholderClientKey;
  }

  String get serverKey {
    try {
      if (dotenv.isInitialized) {
        final key = dotenv.env['MIDTRANS_SERVER_KEY']?.trim();
        if (key != null && key.isNotEmpty) return key;
      }
    } catch (_) {}
    return _placeholderServerKey;
  }

  bool get hasLiveSandboxKey =>
      serverKey != _placeholderServerKey && serverKey.startsWith('SB-Mid-server-');

  static const String sandboxSnapUrl =
      'https://app.sandbox.midtrans.com/snap/v2/vtweb/';

  /// Initialize an order using the selected plan and payment method.
  Future<PaymentOrderModel> createOrder({
    required PricingPlanModel plan,
    required PaymentMethodOption method,
    required String officerName,
    required String officerEmail,
    required String sppgUnit,
  }) async {
    final baseOrder = PaymentOrderModel.create(
      planId: plan.id,
      planName: plan.name,
      planPrice: plan.billedPrice,
      method: method,
      officerName: officerName,
      sppgUnit: sppgUnit,
    );

    if (hasLiveSandboxKey) {
      try {
        final auth = base64Encode(utf8.encode('$serverKey:'));
        final enabledPayments = switch (method.type) {
          PaymentMethodType.qris => ['gopay', 'shopeepay', 'other_qris'],
          PaymentMethodType.bankTransfer => [
              if (method.bankCode != null) '${method.bankCode}_va' else 'bca_va',
            ],
          PaymentMethodType.creditCard => ['credit_card'],
        };

        final response = await http
            .post(
              Uri.parse(sandboxSnapApiUrl),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Basic $auth',
              },
              body: jsonEncode({
                'transaction_details': {
                  'order_id': baseOrder.orderId,
                  'gross_amount': baseOrder.totalAmount,
                },
                'item_details': [
                  {
                    'id': plan.id,
                    'price': baseOrder.planPrice,
                    'quantity': 1,
                    'name': plan.name,
                  },
                  {
                    'id': 'ppn_11',
                    'price': baseOrder.taxAmount,
                    'quantity': 1,
                    'name': 'PPN 11%',
                  },
                  if (baseOrder.adminFee > 0)
                    {
                      'id': 'admin_fee',
                      'price': baseOrder.adminFee,
                      'quantity': 1,
                      'name': 'Biaya Admin ${method.name}',
                    },
                ],
                'customer_details': {
                  'first_name': officerName.trim().isEmpty || officerName == '-'
                      ? 'Petugas SPPG'
                      : officerName,
                  'email': officerEmail,
                  'billing_address': {
                    'first_name': officerName,
                    'address': sppgUnit,
                  },
                },
                'enabled_payments': enabledPayments,
              }),
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final snapToken = data['token'] as String?;
          final redirectUrl = data['redirect_url'] as String?;
          debugPrint(
            'Midtrans Sandbox API: Created Snap token for ${baseOrder.orderId}',
          );
          return baseOrder.copyWith(
            snapToken: snapToken,
            redirectUrl: redirectUrl ?? baseOrder.redirectUrl,
            isLiveSandboxApi: true,
          );
        }
        debugPrint(
          'Midtrans Sandbox API fallback (${response.statusCode}): ${response.body}',
        );
      } catch (e) {
        debugPrint('Midtrans Sandbox API unreachable, using simulator: $e');
      }
    }

    // Simulator mode: brief handshake delay for realistic loading UX
    await Future.delayed(const Duration(milliseconds: 300));

    debugPrint(
      'Midtrans Sandbox: Created order ${baseOrder.orderId} for ${plan.name} - Rp ${baseOrder.totalAmount} via ${method.name}',
    );

    return baseOrder;
  }

  /// Queries real Midtrans Sandbox status API when `isLiveSandboxApi` is active.
  Future<PaymentStatus> checkTransactionStatus(PaymentOrderModel order) async {
    if (!order.isLiveSandboxApi || !hasLiveSandboxKey) {
      return order.status;
    }
    try {
      final auth = base64Encode(utf8.encode('$serverKey:'));
      final response = await http.get(
        Uri.parse('$sandboxCoreApiBase/${order.orderId}/status'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Basic $auth',
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final txStatus = (data['transaction_status'] as String? ?? '').toLowerCase();
        return switch (txStatus) {
          'settlement' || 'capture' => PaymentStatus.settlement,
          'expire' => PaymentStatus.expired,
          'deny' || 'cancel' || 'failure' => PaymentStatus.failed,
          _ => PaymentStatus.pending,
        };
      }
    } catch (_) {}
    return order.status;
  }

  /// Simulates payment completion / settlement in Midtrans Sandbox.
  Future<PaymentOrderModel> simulatePaymentSettlement(
    PaymentOrderModel order,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final settledOrder = order.copyWith(
      status: PaymentStatus.settlement,
    );

    debugPrint(
      'Midtrans Sandbox: Payment settled for order ${settledOrder.orderId}',
    );

    return settledOrder;
  }

  /// Currency formatting helper (e.g. Rp 249.000)
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
