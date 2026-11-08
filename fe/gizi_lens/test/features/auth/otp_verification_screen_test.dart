import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/features/auth/controllers/otp_controller.dart';
import 'package:gizi_lens/features/auth/views/otp_verification_screen.dart';
import 'package:gizi_lens/features/auth/views/widgets/otp_verification_dialog.dart';

void main() {
  group('OtpController Unit Tests', () {
    late OtpController controller;

    setUp(() {
      controller = OtpController(
        email: 'nurulanggraini@gmail.com',
        phone: '+6281234567789',
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial states and masking are correct', () {
      expect(controller.secondsRemaining, equals(48));
      expect(controller.canResend, isFalse);
      expect(controller.isOtpComplete, isFalse);
      expect(controller.maskedEmail, equals('nurulan***@gmail.com'));
      expect(controller.maskedPhone, contains('****'));
    });

    test('updateOtp updates current code and checks completeness', () {
      controller.updateOtp('123');
      expect(controller.currentOtp, equals('123'));
      expect(controller.isOtpComplete, isFalse);

      controller.updateOtp('123456');
      expect(controller.currentOtp, equals('123456'));
      expect(controller.isOtpComplete, isTrue);
    });

    test('verifyOtp requires 6 digits', () async {
      controller.updateOtp('123');
      final fail = await controller.verifyOtp();
      expect(fail, isFalse);
      expect(controller.errorMessage, isNotNull);

      controller.updateOtp('123456');
      final pass = await controller.verifyOtp();
      expect(pass, isTrue);
    });

    test('Random OTP is generated and autoFillOtp populates currentOtp', () {
      expect(controller.generatedOtp.length, equals(6));
      expect(int.tryParse(controller.generatedOtp), isNotNull);

      controller.autoFillOtp();
      expect(controller.currentOtp, equals(controller.generatedOtp));
      expect(controller.isOtpComplete, isTrue);
    });
  });

  group('OtpVerificationScreen & Dialog Widget Tests', () {
    testWidgets('Renders all visual components from otp.png accurately', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OtpVerificationScreen(
            initialEmail: 'nurulag***@gmail.com',
            initialPhone: '+62 812-****-789',
          ),
        ),
      );

      // Verify Back Arrow & Badges
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.text(AppStrings.otpBadge), findsOneWidget);
      expect(find.text(AppStrings.otpTitle), findsOneWidget);
      expect(find.text(AppStrings.otpSubtitle), findsOneWidget);

      // Verify Destination card info
      expect(find.text(AppStrings.otpSentToPrefix), findsOneWidget);
      expect(find.text('nurulag***@gmail.com'), findsOneWidget);
      expect(find.text('+62 812-****-789'), findsOneWidget);
      expect(find.text(AppStrings.btnUbah), findsOneWidget);

      // Verify OTP label & resend info
      expect(find.text(AppStrings.enterOtpLabel), findsOneWidget);
      expect(find.text(AppStrings.haventReceivedCode), findsOneWidget);
      expect(find.text(AppStrings.smsHelp), findsOneWidget);

      // Verify Verification Button & Footer
      expect(find.text(AppStrings.btnVerifikasi), findsOneWidget);
      expect(find.text(AppStrings.privacyPolicy), findsOneWidget);
      expect(find.text(AppStrings.termsOfServiceMBG), findsOneWidget);
    });

    testWidgets('OtpVerificationDialog renders matching Background+Border verifikasi.png', (tester) async {
      bool nextClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  OtpVerificationDialog.show(
                    ctx,
                    onNext: () {
                      nextClicked = true;
                    },
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify Dialog Elements
      expect(find.text(AppStrings.verificationSuccessTitle), findsOneWidget);
      expect(find.text(AppStrings.verificationSuccessSubtitle), findsOneWidget);
      expect(find.text(AppStrings.btnSelanjutnya), findsOneWidget);

      // Verify tap "Selanjutnya"
      await tester.tap(find.text(AppStrings.btnSelanjutnya));
      await tester.pumpAndSettle();
      expect(nextClicked, isTrue);
    });
  });
}
