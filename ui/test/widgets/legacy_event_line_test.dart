import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/messages/ui/widgets/legacy_event_line.dart';

void main() {
  testWidgets('LegacyEventLine shows the grey unsupported line', (t) async {
    await t.pumpWidget(
      const MaterialApp(home: Scaffold(body: LegacyEventLine())),
    );

    expect(find.byKey(const Key('legacy-event')), findsOneWidget);
    expect(
      find.text('This message type is no longer supported'),
      findsOneWidget,
    );
  });
}
