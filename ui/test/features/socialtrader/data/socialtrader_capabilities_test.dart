import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stawi/features/socialtrader/data/socialtrader_capabilities.dart';

void main() {
  group('socialTraderCapabilities over HTTP', () {
    ProviderContainer containerAnswering(http.Response Function() answer) {
      final container = ProviderContainer(
        overrides: [
          capabilitiesHttpClientProvider.overrideWithValue(
            MockClient((request) async {
              expect(request.url.path, '/v1/system/capabilities');
              return answer();
            }),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('canCreatePool is true when the service announces it', () async {
      final container = containerAnswering(
        () => http.Response(
          jsonEncode({
            'api_version': 'v1',
            'capabilities': {'socialtrader_create_pool': true, 'pools': true},
          }),
          200,
        ),
      );
      expect(await container.read(canCreatePoolProvider.future), isTrue);
    });

    test('canCreatePool is false when the flag is off', () async {
      final container = containerAnswering(
        () => http.Response(
          jsonEncode({
            'capabilities': {'socialtrader_create_pool': false},
          }),
          200,
        ),
      );
      expect(await container.read(canCreatePoolProvider.future), isFalse);
    });

    test('a failing or old service announces nothing', () async {
      expect(
        await containerAnswering(() => http.Response('not found', 404))
            .read(canCreatePoolProvider.future),
        isFalse,
      );
      expect(
        await containerAnswering(() => throw http.ClientException('down'))
            .read(canCreatePoolProvider.future),
        isFalse,
      );
    });
  });

  group('parseCapabilities', () {
    test('reads an object of flags', () {
      expect(
        parseCapabilities('{"socialtrader_create_pool":true,"markets":false}'),
        {'socialtrader_create_pool'},
      );
    });

    test('reads the service\'s nested capabilities object', () {
      expect(
        parseCapabilities(
          '{"api_version":"v1","chain_id":14601,"markets":["m1"],'
          '"capabilities":{"socialtrader_create_pool":true,"pools":true,'
          '"multi_market":false}}',
        ),
        {'socialtrader_create_pool', 'pools'},
      );
    });

    test('reads a list under capabilities', () {
      expect(
        parseCapabilities('{"capabilities":["socialtrader_create_pool","x"]}'),
        {'socialtrader_create_pool', 'x'},
      );
    });

    test('anything else is no capability', () {
      expect(parseCapabilities('not json'), isEmpty);
      expect(parseCapabilities('[1,2]'), isEmpty);
      expect(parseCapabilities(''), isEmpty);
    });
  });
}
