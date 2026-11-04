import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/app/app.dart';
import 'package:gizi_lens/core/constants/app_strings.dart';

void main() {
  testWidgets('App launches with SplashScreen initially', (WidgetTester tester) async {
    await tester.pumpWidget(const GiziLensApp());

    // Initially at SplashScreen
    expect(find.text(AppStrings.splashHeaderLeft), findsOneWidget);
    expect(find.text(AppStrings.cloudConnecting), findsOneWidget);

    // Settle pending timers
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
