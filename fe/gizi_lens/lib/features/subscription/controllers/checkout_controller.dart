import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/user_session_service.dart';
import '../models/payment_order_model.dart';
import '../models/pricing_plan_model.dart';
import '../services/midtrans_sandbox_service.dart';

class CheckoutController extends ChangeNotifier {
  final PricingPlanModel plan;
  final List<PaymentMethodOption> availableMethods =
      PaymentMethodOption.availableMethods;

  late PaymentMethodOption _selectedMethod;
  PaymentOrderModel? _currentOrder;
  Future<void>? _persistFuture;
  bool _isLoading = false;
  bool _isProcessingPayment = false;
  bool _isSuccess = false;
  bool _isDisposed = false;
  int _orderRequestSeq = 0;
  String? _errorMessage;

  PaymentMethodOption get selectedMethod => _selectedMethod;
  PaymentOrderModel? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  bool get isProcessingPayment => _isProcessingPayment;
  bool get isSuccess => _isSuccess;
  String? get errorMessage => _errorMessage;
  bool get isLiveMidtransSnap => _currentOrder?.isLiveSandboxApi == true;

  CheckoutController({required this.plan}) {
    _selectedMethod = availableMethods.first; // Default QRIS
    _initOrder();
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  String _resolveCustomerEmail() {
    try {
      final email = FirebaseAuthService.instance.currentUser?.email?.trim();
      if (email != null && email.isNotEmpty) return email;
    } catch (_) {}
    return 'petugas.sppg@gizilens.id';
  }

  void selectMethod(PaymentMethodOption method) {
    if (_selectedMethod.id != method.id) {
      _selectedMethod = method;
      _initOrder();
    }
  }

  Future<void> _initOrder() async {
    final requestSeq = ++_orderRequestSeq;
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final account = UserSessionService.instance.account;
      final customerEmail = _resolveCustomerEmail();
      final order = await MidtransSandboxService.instance.createOrder(
        plan: plan,
        method: _selectedMethod,
        officerName: account.fullName,
        officerEmail: customerEmail,
        sppgUnit: account.unitOperational,
      );
      if (_isDisposed || requestSeq != _orderRequestSeq) return;
      _currentOrder = order;
      _persistFuture = _persistOrder(
        order,
        account.fullName,
        account.unitOperational,
        customerEmail,
      );
    } catch (e) {
      if (_isDisposed || requestSeq != _orderRequestSeq) return;
      _errorMessage = 'Gagal membuat tagihan pembayaran: $e';
    } finally {
      if (!_isDisposed && requestSeq == _orderRequestSeq) {
        _isLoading = false;
        _safeNotify();
      }
    }
  }

  /// Verifies a live Midtrans Snap transaction status against Midtrans / Backend.
  Future<PaymentStatus> verifyLiveMidtransPayment() async {
    final order = _currentOrder;
    if (order == null) return PaymentStatus.pending;

    _isProcessingPayment = true;
    _errorMessage = null;
    _safeNotify();

    try {
      await _persistFuture;
      final status =
          await MidtransSandboxService.instance.checkTransactionStatus(order);
      if (_isDisposed) return status;

      if (status == PaymentStatus.settlement) {
        await _completeSettlement(order);
      } else if (status == PaymentStatus.expired ||
          status == PaymentStatus.failed) {
        _currentOrder = order.copyWith(status: status);
        _errorMessage = status == PaymentStatus.expired
            ? 'Transaksi Midtrans kedaluwarsa. Silakan buat ulang pesanan.'
            : 'Pembayaran Midtrans ditolak atau dibatalkan.';
      }
      return status;
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Gagal memverifikasi status Midtrans: $e';
      }
      return PaymentStatus.pending;
    } finally {
      if (!_isDisposed) {
        _isProcessingPayment = false;
        _safeNotify();
      }
    }
  }

  /// Processes payment settlement (verifies live Midtrans if active, or simulates in Sandbox).
  Future<bool> processPayment() async {
    final order = _currentOrder;
    if (order == null) return false;

    _isProcessingPayment = true;
    _errorMessage = null;
    _safeNotify();

    try {
      await _persistFuture;

      if (order.isLiveSandboxApi) {
        final liveStatus =
            await MidtransSandboxService.instance.checkTransactionStatus(order);
        if (_isDisposed) return false;
        if (liveStatus != PaymentStatus.settlement) {
          _errorMessage =
              'Pembayaran belum terselesaikan di Midtrans. Selesaikan di halaman Midtrans Snap lalu tekan Verifikasi.';
          return false;
        }
        await _completeSettlement(order);
        return true;
      }

      final settled = await MidtransSandboxService.instance
          .simulatePaymentSettlement(order);
      if (_isDisposed) return false;

      await _completeSettlement(settled);
      return true;
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Pembayaran Midtrans gagal: $e';
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _isProcessingPayment = false;
        _safeNotify();
      }
    }
  }

  Future<void> _completeSettlement(PaymentOrderModel order) async {
    _currentOrder = order.copyWith(status: PaymentStatus.settlement);
    _isSuccess = true;

    try {
      await BackendApiService.instance.updateTransactionStatus(
        order.orderId,
        'settlement',
      );
    } catch (_) {}

    await UserSessionService.instance.upgradeSubscription(
      planName: plan.name,
    );
    _safeNotify();
  }

  Future<void> _persistOrder(
    PaymentOrderModel order,
    String officerName,
    String sppgUnit,
    String customerEmail,
  ) async {
    try {
      final uid = FirebaseAuthService.instance.currentUser?.uid;
      await BackendApiService.instance.createTransaction({
        'orderId': order.orderId,
        'planId': plan.id,
        'planName': plan.name,
        'planPrice': order.planPrice,
        'adminFee': order.adminFee,
        'taxAmount': order.taxAmount,
        'totalAmount': order.totalAmount,
        'selectedMethod': {
          'id': _selectedMethod.id,
          'name': _selectedMethod.name,
          'type': _selectedMethod.type.name,
          'bankCode': _selectedMethod.bankCode,
          'fee': _selectedMethod.fee,
        },
        'status': 'pending',
        'officerName': officerName,
        'sppgUnit': sppgUnit,
        'customerEmail': customerEmail,
        'userUid': ?uid,
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
