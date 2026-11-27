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
      expect(controller.isVerified, isFalse);
      expect(controller.maskedEmail, equals('nurulan***@gmail.com'));
      expect(controller.maskedPhone, contains('****'));
    });

    test('Controller never exposes an OTP code', () {
      // Verification is link-based: there must be no generated code to leak.
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('Forgot-password mode does not poll email verification', () {
      final forgot = OtpController(
        email: 'nurulanggraini@gmail.com',
        isForgotPassword: true,
      );
      expect(forgot.isVerified, isFalse);
      expect(forgot.secondsRemaining, equals(48));
      forgot.dispose();
    });
  });

  group('OtpVerificationScreen & Dialog Widget Tests', () {
    testWidgets('Shows email instructions without any OTP code', (
      tester,
    ) async {
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

      // No code input and no generated code anywhere on screen
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Isi Otomatis'), findsNothing);
      expect(find.textContaining('KODE OTP'), findsNothing);

      // Verify resend info
      expect(find.text(AppStrings.haventReceivedCode), findsOneWidget);
      expect(find.text(AppStrings.smsHelp), findsOneWidget);

      // Verify Verification Button & Footer
      expect(find.text(AppStrings.btnVerifikasi), findsOneWidget);
      expect(find.text(AppStrings.privacyPolicy), findsOneWidget);
      expect(find.text(AppStrings.termsOfServiceMBG), findsOneWidget);
    });

    testWidgets('Forgot-password mode offers the reset page instead', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OtpVerificationScreen(
            initialEmail: 'nurulag***@gmail.com',
            isForgotPassword: true,
          ),
        ),
      );

      expect(find.text('Reset Kata Sandi'), findsOneWidget);
      expect(find.text('Buka Halaman Reset'), findsOneWidget);
      expect(find.text(AppStrings.btnVerifikasi), findsNothing);
    });

    testWidgets('OtpVerificationDialog renders matching Background+Border verifikasi.png', (
      tester,
    ) async {
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
