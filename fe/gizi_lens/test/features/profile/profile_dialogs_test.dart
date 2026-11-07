import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';
import 'package:gizi_lens/features/profile/views/dialogs/logout_confirmation_dialog.dart';
import 'package:gizi_lens/features/profile/views/dialogs/profile_updated_success_dialog.dart';
import 'package:gizi_lens/features/profile/views/dialogs/save_profile_confirmation_dialog.dart';

void main() {
  group('Profile Dialogs Widget Tests', () {
    testWidgets('LogoutConfirmationDialog displays all elements and handles callback', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  LogoutConfirmationDialog.show(
                    context,
                    onConfirmLogout: () {
                      confirmed = true;
                    },
                  );
                },
                child: const Text('Open Logout Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Logout Dialog'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.logoutDialogTitle), findsOneWidget);
      expect(find.text(AppStrings.logoutDialogConfirmBtn), findsOneWidget);
      expect(find.text(AppStrings.logoutDialogCancelBtn), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.text(AppStrings.logoutDialogConfirmBtn));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });

    testWidgets('SaveProfileConfirmationDialog displays info and handles callback', (tester) async {
      bool saved = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  SaveProfileConfirmationDialog.show(
                    context,
                    onConfirmSave: () {
                      saved = true;
                    },
                  );
                },
                child: const Text('Open Save Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Save Dialog'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.saveProfileDialogTitle), findsOneWidget);
      expect(find.text(AppStrings.saveProfileDialogSubtitle), findsOneWidget);
      expect(find.text(AppStrings.saveProfileDialogConfirmBtn), findsOneWidget);
      expect(find.text(AppStrings.saveProfileDialogCancelBtn), findsOneWidget);

      await tester.tap(find.text(AppStrings.saveProfileDialogConfirmBtn));
      await tester.pumpAndSettle();

      expect(saved, isTrue);
    });

    testWidgets('ProfileUpdatedSuccessDialog displays success and handles dismiss', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ProfileUpdatedSuccessDialog.show(
                    context,
                    onDismiss: () {
                      dismissed = true;
                    },
                  );
                },
                child: const Text('Open Success Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Success Dialog'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.profileUpdatedSuccessTitle), findsOneWidget);
      expect(find.text(AppStrings.profileUpdatedSuccessSubtitle), findsOneWidget);
      expect(find.text(AppStrings.profileUpdatedBackButton), findsOneWidget);

      await tester.tap(find.text(AppStrings.profileUpdatedBackButton));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });
  });
}
