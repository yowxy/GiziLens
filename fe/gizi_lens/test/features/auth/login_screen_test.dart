import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/features/auth/controllers/login_controller.dart';
import 'package:gizi_lens/features/auth/views/login_screen.dart';

void main() {
  group('LoginController Unit Tests', () {
    late LoginController controller;

    setUp(() {
      controller = LoginController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial states are correct', () {
      expect(controller.rememberMe, isTrue);
      expect(controller.isPasswordVisible, isFalse);
      expect(controller.isLoading, isFalse);
    });

    test('togglePasswordVisibility flips state', () {
      controller.togglePasswordVisibility();
      expect(controller.isPasswordVisible, isTrue);
      controller.togglePasswordVisibility();
      expect(controller.isPasswordVisible, isFalse);
    });

    test('setRememberMe updates state', () {
      controller.setRememberMe(false);
      expect(controller.rememberMe, isFalse);
      controller.setRememberMe(true);
      expect(controller.rememberMe, isTrue);
    });

    test('Field validation checks required fields and password length', () {
      expect(controller.validateEmailOrId(''), isNotNull);
      expect(controller.validateEmailOrId('  '), isNotNull);
      expect(controller.validateEmailOrId('petugas@sppg.id'), isNull);

      expect(controller.validatePassword(''), isNotNull);
      expect(controller.validatePassword('12345'), isNotNull);
      expect(controller.validatePassword('123456'), isNull);
    });
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders all essential elements from 1auth.png', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Verify Title & Subtitle
      expect(find.text(AppStrings.loginTitle), findsOneWidget);
      expect(find.text(AppStrings.portalResmiBadge), findsOneWidget);
      expect(find.text(AppStrings.loginSubtitle), findsOneWidget);

      // Verify Input Labels & Placeholders
      expect(find.text(AppStrings.emailOrOfficerIdLabel), findsOneWidget);
      expect(find.text(AppStrings.sppgResmiBadge), findsOneWidget);
      expect(find.text(AppStrings.passwordLabel), findsOneWidget);

      // Verify Actions
      expect(find.text(AppStrings.rememberMe), findsOneWidget);
      expect(find.text(AppStrings.forgotPassword), findsOneWidget);
      expect(find.text(AppStrings.btnMasuk), findsOneWidget);

      // Verify Managed Access Card
      expect(find.textContaining('Akses Terkelola', findRichText: true), findsOneWidget);

      // Verify Footer
      expect(find.text(AppStrings.privacyPolicy), findsOneWidget);
      expect(find.text(AppStrings.termsOfServiceMBG), findsOneWidget);
      expect(find.text(AppStrings.appVersionString), findsOneWidget);
    });
  });
}
