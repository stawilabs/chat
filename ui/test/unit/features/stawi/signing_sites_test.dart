import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every place in the app a device key signs, by file and method. Each one
/// takes its key from DeviceKeyStore.unlock, behind the device lock. A new
/// signing path fails this test until it is listed here, and it must unlock.
const Map<String, Set<String>> deviceSignSites = {
  'lib/features/stawi/data/stawi_account_service.dart': {
    'deploy', // account deployment (genesis of the account)
    'addDeviceKey', // ADD_KEY
    'contribute', // money: a payment into a room
    'submitEngineCall', // money: loans, payoffs, withdrawals
  },
  'lib/features/stawi/data/stawi_room_service.dart': {
    'signGenesis', // room genesis
    'signedCall', // room calls, votes and secret-ballot commits/reveals
  },
};

/// `.sign(` calls that are not a device key: Matrix Olm signs its own
/// identity payloads.
const Set<String> otherSigners = {
  'lib/core/crypto/e2e_encryption_service.dart',
};

final _methodHeader = RegExp(
  r'^  (?:static )?(?:Future|Stream|Uint8List|[A-Z]\w*)[\w<>?, .]*\s(\w+)\(',
);

Map<String, String> _libSources() => {
  for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
    if (f.path.endsWith('.dart') &&
        !f.path.endsWith('.g.dart') &&
        !f.path.endsWith('.freezed.dart'))
      f.path.replaceAll(r'\', '/'): f.readAsStringSync(),
};

void main() {
  final sources = _libSources();

  test('every device-key signature is listed and unlocks first', () {
    final found = <String, Set<String>>{};
    for (final MapEntry(key: path, value: text) in sources.entries) {
      if (!text.contains('.sign(') || otherSigners.contains(path)) continue;
      final lines = text.split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('.sign(')) continue;
        var h = i;
        while (h >= 0 && _methodHeader.firstMatch(lines[h]) == null) {
          h--;
        }
        expect(h, greaterThanOrEqualTo(0), reason: '$path:${i + 1}');
        final method = _methodHeader.firstMatch(lines[h])!.group(1)!;
        found.putIfAbsent(path, () => {}).add(method);
        expect(
          lines.sublist(h, i + 1).join('\n'),
          contains('_keys.unlock('),
          reason: '$path $method signs without the device lock',
        );
      }
    }
    expect(found, deviceSignSites);
  });

  test('only reading the account takes the key without the lock', () {
    final loads = <String>[];
    for (final MapEntry(key: path, value: text) in sources.entries) {
      for (final m in RegExp(r'keys\.(loadOrCreate|load)\(').allMatches(text)) {
        loads.add('$path ${m.group(1)}');
      }
    }
    // StawiAccountService.status reads the key's address; it signs nothing.
    expect(loads, [
      'lib/features/stawi/data/stawi_account_service.dart loadOrCreate',
    ]);
    final status =
        sources['lib/features/stawi/data/stawi_account_service.dart']!;
    final body = status.substring(
      status.indexOf('Future<StawiAccountStatus> status()'),
      status.indexOf('Future<StawiAccountRef> ensureReady('),
    );
    expect(body, contains('_keys.loadOrCreate('));
    expect(body, isNot(contains('.sign(')));
  });

  test('the app builds its key store only behind the device lock', () {
    final builds = <String>[];
    for (final MapEntry(key: path, value: text) in sources.entries) {
      for (final m in 'DeviceKeyStore('.allMatches(text)) {
        final call = text
            .substring(m.end, text.indexOf(';', m.end))
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (call.startsWith('this._vault')) continue; // the constructor
        builds.add('$path $call');
      }
    }
    const production =
        'lib/features/stawi/data/device_key_store.dart '
        'const SecureStorageDeviceKeyVault(), '
        'gate: ref.watch(signingGateProvider), ), )';
    expect(builds, [production]);
  });
}
