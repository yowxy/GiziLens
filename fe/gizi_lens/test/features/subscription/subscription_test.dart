import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/core/services/user_session_service.dart';
import 'package:gizi_lens/features/dashboard/views/dashboard_screen.dart';
import 'package:gizi_lens/features/dashboard/views/widgets/premium_banner_card.dart';
import 'package:gizi_lens/features/profile/views/widgets/subscription_plan_card.dart';
import 'package:gizi_lens/features/subscription/controllers/checkout_controller.dart';
import 'package:gizi_lens/features/subscription/controllers/pricing_controller.dart';
import 'package:gizi_lens/features/subscription/models/payment_order_model.dart';
import 'package:gizi_lens/features/subscription/models/pricing_plan_model.dart';
import 'package:gizi_lens/features/subscription/services/midtrans_sandbox_service.dart';
import 'package:gizi_lens/features/subscription/views/checkout_screen.dart';
import 'package:gizi_lens/features/subscription/views/pricing_screen.dart';
import 'package:gizi_lens/features/subscription/views/widgets/bundle_card.dart';
import 'package:gizi_lens/features/subscription/views/widgets/payment_method_tile.dart';
import 'package:gizi_lens/features/subscription/views/widgets/qris_matrix_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    UserSessionService.instance.reset();
  });

  group('PricingPlanModel & PricingController Tests', () {
    test('Only a single GiziLens Premium plan is configured', () {
      final plans = PricingPlanModel.defaultPlans;
      expect(plans.length, equals(1));

      final premium = PricingPlanModel.defaultPlan;
      expect(premium.id, equals('plan_premium'));
      expect(premium.name, equals('GiziLens Premium'));
      expect(premium.billedPrice, equals(299000));
      expect(premium.isPopular, isTrue);
      expect(premium.originalPrice, isNull);
      expect(premium.savingsPercentage, equals(0));
    });

    test('PricingController defaults to single GiziLens Premium plan', () {
      final controller = PricingController();
      expect(controller.plans.length, equals(1));
      expect(controller.selectedPlan.id, equals('plan_premium'));
      expect(controller.selectedPlan.name, equals('GiziLens Premium'));
      expect(controller.selectedTabIndex, equals(0));

      controller.dispose();
    });
  });

  group('MidtransSandboxService & CheckoutController Tests', () {
    test('Rupiah formatting produces correct Indonesian currency format', () {
      expect(MidtransSandboxService.formatRupiah(99000), equals('Rp 99.000'));
      expect(MidtransSandboxService.formatRupiah(249000), equals('Rp 249.000'));
      expect(MidtransSandboxService.formatRupiah(0), equals('Rp 0'));
    });

    test('enabledPaymentsFor maps Midtrans Snap channels accurately', () {
      final methods = PaymentMethodOption.availableMethods;
      expect(
        MidtransSandboxService.enabledPaymentsFor(methods[0]),
        equals(['gopay', 'shopeepay', 'other_qris']),
      );
      expect(
        MidtransSandboxService.enabledPaymentsFor(methods[1]),
        equals(['bca_va']),
      );
      expect(
        MidtransSandboxService.enabledPaymentsFor(methods[2]),
        equals(['echannel']),
      );
      expect(
        MidtransSandboxService.enabledPaymentsFor(methods[5]),
        equals(['credit_card']),
      );
    });

    test('createOrder calculates PPN 11% with waived admin fee', () async {
      final plan = PricingPlanModel.defaultPlan; // Rp299.000
      final methodVa = PaymentMethodOption.availableMethods[1]; // BCA VA, fee 0

      final order = await MidtransSandboxService.instance.createOrder(
        plan: plan,
        method: methodVa,
        officerName: 'Nurul Anggraini, S.Gz',
        officerEmail: 'petugas.sppg@gizilens.id',
        sppgUnit: 'SPPG Cibinong Sentral 02',
      );

      final expectedTax = (plan.billedPrice * 0.11).round();
      final expectedTotal = plan.billedPrice + expectedTax;

      expect(order.planId, equals('plan_premium'));
      expect(order.planPrice, equals(plan.billedPrice));
      expect(order.taxAmount, equals(expectedTax));
      expect(order.adminFee, equals(0));
      expect(order.totalAmount, equals(expectedTotal));
      expect(order.status, equals(PaymentStatus.pending));
      expect(order.vaNumber, isNotNull);
      expect(order.redirectUrl, contains('sandbox.midtrans.com'));
    });

    test('simulatePaymentSettlement upgrades order status to settlement', () async {
      final plan = PricingPlanModel.defaultPlan;
      final method = PaymentMethodOption.availableMethods[0]; // QRIS, fee 0

      final initialOrder = await MidtransSandboxService.instance.createOrder(
        plan: plan,
        method: method,
        officerName: 'Nurul Anggraini, S.Gz',
        officerEmail: 'petugas.sppg@gizilens.id',
        sppgUnit: 'SPPG Cibinong Sentral 02',
      );

      final settledOrder = await MidtransSandboxService.instance
          .simulatePaymentSettlement(initialOrder);

      expect(settledOrder.status, equals(PaymentStatus.settlement));
    });

    test('CheckoutController full flow simulates settlement and upgrades session', () async {
      final plan = PricingPlanModel.defaultPlan;
      final controller = CheckoutController(plan: plan);

      // Wait for initial order generation (createOrder has a 300ms delay)
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(controller.currentOrder, isNotNull);
      expect(controller.selectedMethod.id, equals('qris'));

      // Switch to BCA VA
      final bcaVa = controller.availableMethods[1];
      controller.selectMethod(bcaVa);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(controller.selectedMethod.id, equals('bca_va'));
      expect(controller.currentOrder?.adminFee, equals(0));

      // Process payment
      final success = await controller.processPayment();
      expect(success, isTrue);
      expect(controller.isSuccess, isTrue);
      expect(controller.currentOrder?.status, equals(PaymentStatus.settlement));

      // Verify UserSessionService subscription is updated
      expect(UserSessionService.instance.account.isPremium, isTrue);
      expect(
        UserSessionService.instance.account.subscriptionPlan,
        equals('GiziLens Premium'),
      );

      controller.dispose();
    });
  });

  group('Widget Tests: PricingScreen & CheckoutScreen', () {
    testWidgets('PricingScreen renders single Premium plan and Free vs Premium comparison', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        const MaterialApp(
          home: PricingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paket Langganan SPPG'), findsOneWidget);
      expect(find.text('GiziLens Premium'), findsWidgets);
      expect(find.text('Perbandingan Free vs Premium'), findsOneWidget);
      expect(find.byType(BundleCard), findsOneWidget);
      expect(find.text('Lanjutkan'), findsOneWidget);
    });

    testWidgets('CheckoutScreen renders Sandbox banner and payment methods', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      final plan = PricingPlanModel.defaultPlan;

      await tester.pumpWidget(
        MaterialApp(
          home: CheckoutScreen(plan: plan),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pembayaran Paket SPPG'), findsOneWidget);
      expect(find.text('MODE MIDTRANS SANDBOX'), findsOneWidget);
      expect(find.text('Ringkasan Tagihan'), findsOneWidget);
      expect(find.text('Pilih Metode Pembayaran'), findsOneWidget);
      expect(find.byType(QrisMatrixWidget), findsOneWidget);
      expect(find.byType(PaymentMethodTile), findsWidgets);
      expect(find.text('Bayar Sekarang'), findsOneWidget);
    });

    testWidgets('PricingScreen renders cleanly on compact 360dp phone width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 780));

      await tester.pumpWidget(
        const MaterialApp(
          home: PricingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BundleCard), findsOneWidget);
      expect(find.text('Gratis'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
    });

    testWidgets('SubscriptionPlanCard hides manage/upgrade button when premium is active', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubscriptionPlanCard(
              planName: 'GiziLens Premium',
              isPremium: true,
              scansUsed: 12,
              monthlyQuota: 500,
              onUpgradeTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('GiziLens Premium'), findsOneWidget);
      expect(find.text('PREMIUM AKTIF'), findsOneWidget);
      expect(find.text('12 dari 500 scan'), findsOneWidget);
      expect(find.text('488 scan tersisa'), findsOneWidget);
      expect(find.text('500 Scan AI / bulan'), findsOneWidget);
      expect(find.text('Kelola Paket Langganan'), findsNothing);
      expect(find.text(AppStrings.btnUpgradePremium), findsNothing);
    });

    testWidgets('DashboardScreen hides PremiumBannerCard and shows PRO UX after upgrade', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() async {
        UserSessionService.instance.reset();
        await tester.binding.setSurfaceSize(null);
      });

      await UserSessionService.instance.upgradeSubscription(
        planName: 'GiziLens Premium',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PremiumBannerCard), findsNothing);
      expect(find.text(AppStrings.premiumCta), findsNothing);
      expect(find.text('Kelola Paket Langganan'), findsNothing);
      expect(find.text('GiziLens Premium'), findsOneWidget);
      expect(find.text('${AppStrings.heroActionBadge} • PRO'), findsOneWidget);
    });
  });
}
