import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/features/auth/views/register_success_screen.dart';

void main() {
  group('RegisterSuccessScreen Widget Tests', () {
    testWidgets('Renders all visual elements from 02 registrasi berhasil.png', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterSuccessScreen(
            email: 'nurul.gizi@gmail.com',
            role: 'Ahli Gizi Lapangan',
            unit: 'SPPG Cibinong Sentral 02',
            autoRedirect: false,
          ),
        ),
      );

      // Verify Title & Subtitle
      expect(find.text(AppStrings.registrationSuccessTitle), findsOneWidget);
      expect(find.text(AppStrings.registrationSuccessSubtitle), findsOneWidget);

      // Verify Summary Details Card
      expect(find.text(AppStrings.registeredAccountLabel), findsOneWidget);
      expect(find.text('nurul.gizi@gmail.com'), findsOneWidget);

      expect(find.text(AppStrings.proposedRoleLabel), findsOneWidget);
      expect(find.text('Ahli Gizi Lapangan'), findsOneWidget);

      expect(find.text(AppStrings.assignmentUnitLabel), findsOneWidget);
      expect(find.text('SPPG Cibinong Sentral 02'), findsOneWidget);

      // Verify Buttons
      expect(find.text(AppStrings.btnKembaliKeLogin), findsOneWidget);
      expect(find.text(AppStrings.btnMasukDashboard), findsOneWidget);

      // Verify Footer Version
      expect(find.text(AppStrings.appVersionString), findsOneWidget);
    });
  });
}
