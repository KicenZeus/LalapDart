import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lalapan_mobile/main.dart';

void main() {
  testWidgets('Lalapan App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LalapanApp(),
      ),
    );
  });
}
