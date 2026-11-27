import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/backend_api_service.dart';
import '../models/payment_order_model.dart';
import '../models/pricing_plan_model.dart';

/// Service managing Midtrans Payment Gateway interactions.
///
/// Resolution order when creating an order:
/// 1. Backend Midtrans Snap gateway (`/api/v1/payment/create-transaction`),
///    keeping `MIDTRANS_SERVER_KEY` safely on the server.
/// 2. Direct Midtrans Sandbox Snap API if `MIDTRANS_SERVER_KEY` is configured
///    in client `.env` (supports both `SB-Mid-server-*` and `Mid-server-*`).
/// 3. Deterministic Midtrans Sandbox Simulator for offline demos & widget tests.
class MidtransSandboxService {
  MidtransSandboxService._();
  static final MidtransSandboxService instance = MidtransSandboxService._();

  static const String _placeholderClientKey = 'SB-Mid-client-GiziLens2026';
  static const String _placeholderServerKey = 'SB-Mid-server-GiziLens2026';
  static const String sandboxSnapApiUrl =
      'https://app.sandbox.midtrans.com/snap/v1/transactions';
  static const String sandboxCoreApiBase =
      'https://api.sandbox.midtrans.com/v2';

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
      serverKey != _placeholderServerKey &&
      (serverKey.startsWith('SB-Mid-server-') ||
          serverKey.startsWith('Mid-server-'));

  static const String sandboxSnapUrl =
      'https://app.sandbox.midtrans.com/snap/v2/vtweb/';

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

  /// Initialize an order using the selected plan and payment method.
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

    // 1. Prefer backend Midtrans Snap gateway so server credentials stay private.
    try {
      final backendResp =
          await BackendApiService.instance.createMidtransTransaction({
        'order_id': baseOrder.orderId,
        'plan_id': plan.id,
        'plan_name': plan.name,
        'gross_amount': baseOrder.totalAmount,
        'customer_name': safeName,
        'customer_email': safeEmail,
        'payment_method': method.id,
      });
      if (backendResp != null) {
        final mode = (backendResp['mode'] as String? ?? '').toLowerCase();
        final snapToken = backendResp['snap_token'] as String?;
        final redirectUrl = backendResp['redirect_url'] as String?;
        final isLiveBackend = mode.startsWith('midtrans_');
        if (isLiveBackend &&
            ((snapToken != null && snapToken.isNotEmpty) ||
                (redirectUrl != null && redirectUrl.isNotEmpty))) {
          return baseOrder.copyWith(
            snapToken: snapToken,
            redirectUrl: redirectUrl ?? baseOrder.redirectUrl,
            isLiveSandboxApi: true,
          );
        }
      }
    } catch (e) {
      debugPrint('Backend Midtrans endpoint fallback: $e');
    }

    // 2. Fallback to direct Midtrans Sandbox Snap API if configured in client .env.
    if (hasLiveSandboxKey) {
      try {
        final auth = base64Encode(utf8.encode('$serverKey:'));
        final enabledPayments = enabledPaymentsFor(method);

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
                  'first_name': safeName,
                  'email': safeEmail,
                  'billing_address': {
                    'first_name': safeName,
                    'address': sppgUnit,
                  },
                },
                'enabled_payments': enabledPayments,
                if (method.type == PaymentMethodType.creditCard)
                  'credit_card': {'secure': true},
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

    // 3. Simulator mode: brief handshake delay for offline/test UX.
    await Future.delayed(const Duration(milliseconds: 300));

    debugPrint(
      'Midtrans Sandbox: Created order ${baseOrder.orderId} for ${plan.name} - Rp ${baseOrder.totalAmount} via ${method.name}',
    );

    return baseOrder;
  }

  /// Queries Midtrans transaction status via backend first, then direct Sandbox Core API.
  Future<PaymentStatus> checkTransactionStatus(PaymentOrderModel order) async {
    try {
      final backendResp =
          await BackendApiService.instance.checkMidtransStatus(order.orderId);
      if (backendResp != null) {
        final mode = (backendResp['mode'] as String? ?? '').toLowerCase();
        final txStatus =
            (backendResp['transaction_status'] as String? ?? '').toLowerCase();
        if (mode.startsWith('midtrans_') || txStatus == 'settlement') {
          return _parseMidtransStatus(txStatus);
        }
      }
    } catch (_) {}

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
        final txStatus =
            (data['transaction_status'] as String? ?? '').toLowerCase();
        return _parseMidtransStatus(txStatus);
      }
    } catch (_) {}
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

  /// Currency formatting helper (e.g. Rp 149.000)
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
