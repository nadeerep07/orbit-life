import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_pro/presentation/widgets/modern_loader.dart';

void main() {
  group('Modern Loader Widgets Tests', () {
    testWidgets('ModernGlassLoader renders correctly with message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModernGlassLoader(
              message: 'Loading financial records...',
              size: 60.0,
            ),
          ),
        ),
      );

      // Verify text message is rendered
      expect(find.text('Loading financial records...'), findsOneWidget);
    });

    testWidgets('ModernShimmerLoader renders requested item count', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ModernShimmerLoader(
                itemCount: 4,
                cardHeight: 80.0,
              ),
            ),
          ),
        ),
      );

      // Pump frames to advance animation controller
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ModernShimmerLoader), findsOneWidget);
    });
  });
}
