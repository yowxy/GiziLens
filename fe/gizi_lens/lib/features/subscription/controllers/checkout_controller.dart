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

  CheckoutController({required this.plan}) {
    _selectedMethod = availableMethods.first; // Default QRIS
    _initOrder();
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
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
      final order = await MidtransSandboxService.instance.createOrder(
        plan: plan,
        method: _selectedMethod,
        officerName: account.fullName,
        officerEmail: 'petugas.sppg@gizilens.id',
        sppgUnit: account.unitOperational,
      );
      if (_isDisposed || requestSeq != _orderRequestSeq) return;
      _currentOrder = order;
      unawaited(_persistOrder(order, account.fullName, account.unitOperational));
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

  /// Processes Sandbox payment settlement.
  Future<bool> processPayment() async {
    if (_currentOrder == null) return false;

    _isProcessingPayment = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final settled = await MidtransSandboxService.instance
          .simulatePaymentSettlement(_currentOrder!);

      if (_isDisposed) return false;
      _currentOrder = settled;
      _isSuccess = true;

      unawaited(
        BackendApiService.instance.updateTransactionStatus(
          settled.orderId,
          'settlement',
        ),
      );

      // Upgrade active user session subscription
      await UserSessionService.instance.upgradeSubscription(
        planName: plan.name,
      );

      _safeNotify();
      return true;
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Simulasi pembayaran Midtrans gagal: $e';
      }
      return false;
    } finally {
      if (!_isDisposed) {
        _isProcessingPayment = false;
        _safeNotify();
      }
    }
  }

  Future<void> _persistOrder(
    PaymentOrderModel order,
    String officerName,
    String sppgUnit,
  ) async {
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
      'customerEmail': 'petugas.sppg@gizilens.id',
      'userUid': ?uid,
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
