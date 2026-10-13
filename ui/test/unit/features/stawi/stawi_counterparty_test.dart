import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/data/stawi_counterparty.dart';
import 'package:stawi/features/stawi/data/stawi_identity.dart';

void main() {
  test('without a directory a lookup says so, never "no account"', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(counterpartyAccountProvider('p2'), (_, _) {});
    addTearDown(sub.close);
    await expectLater(
      container.read(counterpartyAccountProvider('p2').future),
      throwsA(isA<StawiUnavailable>()),
    );
  });

  test('a directory lookup supplies the counterparty\'s account', () async {
    final account = Uint8List.fromList(List.filled(20, 7));
    final container = ProviderContainer(
      overrides: [
        counterpartyAccountsProvider.overrideWithValue(
          (profileId) async => profileId == 'p2' ? account : null,
        ),
      ],
    );
    addTearDown(container.dispose);
    final contact = await container.read(
      counterpartyAccountProvider('p2').future,
    );
    expect(contact!.address, account);
    expect(contact.profileId, 'p2');
    expect(
      await container.read(counterpartyAccountProvider('p3').future),
      isNull,
    );
  });
}
