import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/features/auth/controllers/forgot_password_controller.dart';
import 'package:gizi_lens/features/auth/views/forgot_password_screen.dart';

void main() {
  group('ForgotPasswordController Unit Tests', () {
    late ForgotPasswordController controller;

    setUp(() {
      controller = ForgotPasswordController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial states are correct', () {
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('validateEmail validates correctly', () {
      expect(controller.validateEmail(''), isNotNull);
      expect(controller.validateEmail('invalid'), isNotNull);
      expect(controller.validateEmail('nurul@gmail.com'), isNull);
    });
  });

  group('ForgotPasswordScreen Widget Tests', () {
    testWidgets('Renders essential elements for email input before OTP', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      );

      // Verify Header & Badge
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.text(AppStrings.forgotPasswordBadge), findsOneWidget);
      expect(find.text(AppStrings.forgotPasswordTitle), findsOneWidget);
      expect(find.text(AppStrings.forgotPasswordSubtitle), findsOneWidget);

      // Verify Input Field & Action Button
      expect(find.text(AppStrings.registeredEmailHint), findsOneWidget);
      expect(find.text(AppStrings.btnSendOtp), findsOneWidget);

      // Verify Footer
      expect(find.text(AppStrings.privacyPolicy), findsOneWidget);
      expect(find.text(AppStrings.termsOfServiceMBG), findsOneWidget);
    });
  });
}
