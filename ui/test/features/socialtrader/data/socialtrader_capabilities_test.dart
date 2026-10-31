import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/socialtrader/data/socialtrader_capabilities.dart';

void main() {
  group('parseCapabilities', () {
    test('reads an object of flags', () {
      expect(
        parseCapabilities('{"socialtrader_create_pool":true,"markets":false}'),
        {'socialtrader_create_pool'},
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
