import 'package:flutter_test/flutter_test.dart';

import 'package:cbh_to_pgn/main.dart';

void main() {
  testWidgets('home page renders the file selection button', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Select database files'), findsOneWidget);
    expect(find.text('CBH → PGN'), findsOneWidget);
  });
}
