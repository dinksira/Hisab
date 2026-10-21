import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app/app.dart';

void main() {
  testWidgets('HisabApp smoke test renders WelcomeScreen and brand identity', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HisabApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify brand mark and slogan appear
    expect(find.text('Hisab'), findsWidgets);
    expect(find.text('Know your money.\nOwn your future.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Explore Demo Environment'), findsOneWidget);
  });
}
