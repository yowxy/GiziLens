import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/features/auth/controllers/register_controller.dart';
import 'package:gizi_lens/features/auth/views/register_screen.dart';

void main() {
  group('RegisterController Unit Tests', () {
    late RegisterController controller;

    setUp(() {
      controller = RegisterController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial states are correct', () {
      expect(controller.isPasswordVisible, isFalse);
      expect(controller.isConfirmPasswordVisible, isFalse);
      expect(controller.agreeTerms, isFalse);
      expect(controller.isLoading, isFalse);
      expect(controller.isFormFilled, isFalse);
    });

    test('togglePasswordVisibility flips state', () {
      controller.togglePasswordVisibility();
      expect(controller.isPasswordVisible, isTrue);
      controller.togglePasswordVisibility();
      expect(controller.isPasswordVisible, isFalse);
    });

    test('toggleConfirmPasswordVisibility flips state', () {
      controller.toggleConfirmPasswordVisibility();
      expect(controller.isConfirmPasswordVisible, isTrue);
      controller.toggleConfirmPasswordVisibility();
      expect(controller.isConfirmPasswordVisible, isFalse);
    });

    test('setAgreeTerms updates state', () {
      controller.setAgreeTerms(true);
      expect(controller.agreeTerms, isTrue);
      controller.setAgreeTerms(false);
      expect(controller.agreeTerms, isFalse);
    });

    test('validateFullName enforces required and minimum length', () {
      expect(controller.validateFullName(''), isNotNull);
      expect(controller.validateFullName('AB'), isNotNull);
      expect(controller.validateFullName('Nurul Anggraini'), isNull);
    });

    test('validateEmail checks standard email syntax', () {
      expect(controller.validateEmail(''), isNotNull);
      expect(controller.validateEmail('invalid-email'), isNotNull);
      expect(controller.validateEmail('nurul@gmail.com'), isNull);
    });

    test('validatePhone checks valid Indonesian phone format', () {
      expect(controller.validatePhone(''), isNotNull);
      expect(controller.validatePhone('123'), isNotNull);
      expect(controller.validatePhone('+6281234567890'), isNull);
      expect(controller.validatePhone('081234567890'), isNull);
    });

    test('validatePassword enforces 8+ chars and combination of letter and number', () {
      expect(controller.validatePassword(''), isNotNull);
      expect(controller.validatePassword('pass'), isNotNull);
      expect(controller.validatePassword('passwordonly'), isNotNull);
      expect(controller.validatePassword('12345678'), isNotNull);
      expect(controller.validatePassword('Password123'), isNull);
    });

    test('validateConfirmPassword checks match against password', () {
      controller.passwordController.text = 'Password123';
      expect(controller.validateConfirmPassword(''), isNotNull);
      expect(controller.validateConfirmPassword('WrongPass'), isNotNull);
      expect(controller.validateConfirmPassword('Password123'), isNull);
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('Renders all essential visual components from 02 registrasi.png', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      // Verify Header & Badge
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.text(AppStrings.registerBadge), findsOneWidget);
      expect(find.text(AppStrings.registerTitle), findsOneWidget);
      expect(find.text(AppStrings.registerSubtitle), findsOneWidget);

      // Verify Input Fields
      expect(find.text(AppStrings.fullNameFieldHint), findsOneWidget);
      expect(find.text(AppStrings.emailActiveHint), findsOneWidget);
      expect(find.text(AppStrings.phoneNumberHint), findsOneWidget);
      expect(find.text(AppStrings.registerPasswordHint), findsOneWidget);
      expect(find.text(AppStrings.confirmPasswordHint), findsOneWidget);
      expect(find.text(AppStrings.registerPasswordHelper), findsOneWidget);

      // Verify Terms Checkbox & Button
      expect(find.textContaining('Syarat dan Ketentuan', findRichText: true), findsOneWidget);
      expect(find.text(AppStrings.btnDaftarAkun), findsOneWidget);

      // Verify Footer
      expect(find.text(AppStrings.privacyPolicy), findsOneWidget);
      expect(find.text(AppStrings.termsOfServiceMBG), findsOneWidget);
      expect(find.text(AppStrings.appVersionString), findsOneWidget);
    });
  });
}
