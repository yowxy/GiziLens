import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/core/services/firebase_auth_service.dart';
import 'package:gizi_lens/features/auth/controllers/reset_password_controller.dart';
import 'package:gizi_lens/features/auth/views/reset_password_screen.dart';

void main() {
  group('ResetPasswordController Unit Tests', () {
    late ResetPasswordController controller;

    setUp(() {
      controller = ResetPasswordController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial states are correct', () {
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.isPasswordVisible, isFalse);
      expect(controller.isConfirmPasswordVisible, isFalse);
    });

    test('validateCode rejects empty and too-short input', () {
      expect(controller.validateCode(''), isNotNull);
      expect(controller.validateCode('abc'), isNotNull);
      expect(
        controller.validateCode(
          'https://example.com/__/auth/action?oobCode=ABC123456789',
        ),
        isNull,
      );
    });

    test('validatePassword enforces length and mixed characters', () {
      expect(controller.validatePassword(''), isNotNull);
      expect(controller.validatePassword('abc12'), isNotNull);
      expect(controller.validatePassword('abcdefgh'), isNotNull);
      expect(controller.validatePassword('abc12345'), isNull);
    });

    test('validateConfirmPassword compares with password field', () {
      controller.passwordController.text = 'abc12345';
      expect(controller.validateConfirmPassword('abc12345'), isNull);
      expect(controller.validateConfirmPassword('abc12346'), isNotNull);
    });

    testWidgets('submit succeeds in offline mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(key: controller.formKey, child: const SizedBox.shrink()),
          ),
        ),
      );

      controller.codeController.text =
          'https://example.com/__/auth/action?oobCode=ABC123456789';
      controller.passwordController.text = 'abc12345';
      controller.confirmPasswordController.text = 'abc12345';

      // Firebase is not initialized in tests, so the service simulates success.
      expect(await controller.submit(), isTrue);
      expect(controller.errorMessage, isNull);
    });
  });

  group('FirebaseAuthService.extractOobCode', () {
    test('extracts code from a full reset link', () {
      const link =
          'https://gizilens-32aa6.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=XYZ789&apiKey=abc&lang=en';
      expect(FirebaseAuthService.extractOobCode(link), 'XYZ789');
    });

    test('decodes URL-encoded code and accepts raw code', () {
      expect(
        FirebaseAuthService.extractOobCode('https://x.test/a?oobCode=A%2FB'),
        'A/B',
      );
      expect(FirebaseAuthService.extractOobCode('RAWCODE123'), 'RAWCODE123');
      expect(FirebaseAuthService.extractOobCode('   '), '');
    });
  });

  group('ResetPasswordScreen Widget Tests', () {
    testWidgets('Renders new password form', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(email: 'nurul@example.com'),
        ),
      );

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.text(AppStrings.resetPasswordBadge), findsOneWidget);
      expect(find.text(AppStrings.resetPasswordTitle), findsOneWidget);
      expect(find.text(AppStrings.resetPasswordSubtitle), findsOneWidget);
      expect(find.text(AppStrings.resetCodeHint), findsOneWidget);
      expect(find.text(AppStrings.newPasswordHint), findsOneWidget);
      expect(find.text(AppStrings.btnSavePassword), findsOneWidget);
      expect(find.text('nurul@example.com'), findsOneWidget);
    });
  });
}
