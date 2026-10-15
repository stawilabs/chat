import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/ui/stawi_feedback.dart';

/// A money action invalidates what a screen under another route watches (its
/// subscription paused). flutter_riverpod 3.3.2-dev.2 asserted there and then
/// stopped refreshing anything; plain invalidation must keep working.
void main() {
  testWidgets('a covered screen reads again, and keeps reading again', (
    tester,
  ) async {
    var reads = 0;
    final balance = FutureProvider.autoDispose<int>((ref) async => ++reads);
    final navigator = GlobalKey<NavigatorState>();
    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorKey: navigator,
          home: Consumer(
            builder: (context, ref, _) {
              container = moneyContainer(context);
              final value = ref.watch(balance).value;
              return Text('balance $value', key: const Key('balance'));
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('balance 1'), findsOneWidget);

    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Text('on top')),
    );
    await tester.pumpAndSettle();

    invalidateAll(container, [balance]);
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('balance 2'), findsOneWidget);

    invalidateAll(container, [balance]);
    await tester.pumpAndSettle();
    expect(find.text('balance 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
