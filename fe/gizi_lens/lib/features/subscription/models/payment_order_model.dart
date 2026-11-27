enum PaymentMethodType {
  qris,
  bankTransfer,
  creditCard,
}

class PaymentMethodOption {
  final String id;    
  final String name;
  final String subtitle;
  final PaymentMethodType type;
  final String iconAssetOrName;
  final String? bankCode;
  final int fee;

  const PaymentMethodOption({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.type,
    required this.iconAssetOrName,
    this.bankCode,
    this.fee = 0,
  });

  static const List<PaymentMethodOption> availableMethods = [
    PaymentMethodOption(
      id: 'qris',
      name: 'QRIS (Semua Pembayaran)',
      subtitle: 'GoPay, ShopeePay, DANA, OVO, LinkAja & BCA Mobile',
      type: PaymentMethodType.qris,
      iconAssetOrName: 'qris',
      fee: 0,
    ),
    PaymentMethodOption(
      id: 'bca_va',
      name: 'BCA Virtual Account',
      subtitle: 'Verifikasi instan otomatis 24 jam',
      type: PaymentMethodType.bankTransfer,
      iconAssetOrName: 'bca',
      bankCode: 'bca',
      fee: 0,
    ),
    PaymentMethodOption(
      id: 'mandiri_va',
      name: 'Mandiri Virtual Account',
      subtitle: 'Transfer via Livin by Mandiri & ATM',
      type: PaymentMethodType.bankTransfer,
      iconAssetOrName: 'mandiri',
      bankCode: 'mandiri',
      fee: 0,
    ),
    PaymentMethodOption(
      id: 'bri_va',
      name: 'BRI Virtual Account (BRIVA)',
      subtitle: 'Transfer via BRImo & ATM BRI',
      type: PaymentMethodType.bankTransfer,
      iconAssetOrName: 'bri',
      bankCode: 'bri',
      fee: 0,
    ),
    PaymentMethodOption(
      id: 'bni_va',
      name: 'BNI Virtual Account',
      subtitle: 'Transfer via BNI Mobile & ATM',
      type: PaymentMethodType.bankTransfer,
      iconAssetOrName: 'bni',
      bankCode: 'bni',
      fee: 0,
    ),
    PaymentMethodOption(
      id: 'credit_card',
      name: 'Kartu Kredit / Debit Online',
      subtitle: 'Visa, MasterCard, JCB dengan 3D Secure',
      type: PaymentMethodType.creditCard,
      iconAssetOrName: 'card',
      fee: 0,
    ),
  ];
}

enum PaymentStatus {
  pending,
  settlement,
  failed,
  expired,
}

class PaymentOrderModel {
  final String orderId;
  final String planId;
  final String planName;
  final int planPrice;
  final int adminFee;
  final int taxAmount; // PPN 11%
  final int totalAmount;
  final PaymentMethodOption selectedMethod;
  final PaymentStatus status;
  final DateTime createdAt;
  final String? vaNumber;
  final String? qrPayload;
  final String? redirectUrl;
  final String? snapToken;
  final bool isLiveSandboxApi;
  final String? officerName;
  final String? sppgUnit;

  const PaymentOrderModel({
    required this.orderId,
    required this.planId,
    required this.planName,
    required this.planPrice,
    required this.adminFee,
    required this.taxAmount,
    required this.totalAmount,
    required this.selectedMethod,
    this.status = PaymentStatus.pending,
    required this.createdAt,
    this.vaNumber,
    this.qrPayload,
    this.redirectUrl,
    this.snapToken,
    this.isLiveSandboxApi = false,
    this.officerName,
    this.sppgUnit,
  });

  factory PaymentOrderModel.create({
    required String planId,
    required String planName,
    required int planPrice,
    required PaymentMethodOption method,
    String? officerName,
    String? sppgUnit,
    String? snapToken,
    String? redirectUrl,
    bool isLiveSandboxApi = false,
  }) {
    final epoch = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = epoch.length >= 8 ? epoch.substring(epoch.length - 8) : epoch;
    final orderId = 'GIZI-$suffix';
    final adminFee = method.fee;
    final taxAmount = (planPrice * 0.11).round();
    final totalAmount = planPrice + adminFee + taxAmount;

    // Generate mock VA number for sandbox test
    String? va;
    if (method.bankCode != null) {
      final codePrefix = switch (method.bankCode) {
        'bca' => '80012',
        'mandiri' => '70014',
        'bri' => '12845',
        'bni' => '88019',
        _ => '99001',
      };
      final vaTail = epoch.length >= 9 ? epoch.substring(epoch.length - 9) : epoch.padLeft(9, '0');
      va = '$codePrefix$vaTail';
    }

    return PaymentOrderModel(
      orderId: orderId,
      planId: planId,
      planName: planName,
      planPrice: planPrice,
      adminFee: adminFee,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      selectedMethod: method,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
      vaNumber: va,
      qrPayload: method.type == PaymentMethodType.qris
          ? '00020101021226670014ID.LINKAJA.WWW01189360091100200547070215${orderId}52045812530336054${totalAmount}5802ID5914GIZILENS SPPG6007CIBINONG6304'
          : null,
      redirectUrl: redirectUrl ??
          'https://app.sandbox.midtrans.com/snap/v2/vtweb/$orderId',
      snapToken: snapToken,
      isLiveSandboxApi: isLiveSandboxApi,
      officerName: officerName,
      sppgUnit: sppgUnit,
    );
  }

  PaymentOrderModel copyWith({
    PaymentStatus? status,
    String? vaNumber,
    String? qrPayload,
    String? redirectUrl,
    String? snapToken,
    bool? isLiveSandboxApi,
  }) {
    return PaymentOrderModel(
      orderId: orderId,
      planId: planId,
      planName: planName,
      planPrice: planPrice,
      adminFee: adminFee,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      selectedMethod: selectedMethod,
      status: status ?? this.status,
      createdAt: createdAt,
      vaNumber: vaNumber ?? this.vaNumber,
      qrPayload: qrPayload ?? this.qrPayload,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      snapToken: snapToken ?? this.snapToken,
      isLiveSandboxApi: isLiveSandboxApi ?? this.isLiveSandboxApi,
      officerName: officerName,
      sppgUnit: sppgUnit,
    );
  }
}
