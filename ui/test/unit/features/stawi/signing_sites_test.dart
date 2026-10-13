import 'dart:io';

// The analyzer comes with build_runner; the guard parses lib/ with it so a
// signature is found whatever its indentation, spacing or form.
// ignore: depend_on_referenced_packages
import 'package:analyzer/dart/analysis/utilities.dart';
// ignore: depend_on_referenced_packages
import 'package:analyzer/dart/ast/ast.dart';
// ignore: depend_on_referenced_packages
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every place in the app a device key signs, as `file method`. Each one takes
/// its key from DeviceKeyStore.unlock, behind the device lock. A new signing
/// path fails this test until it is listed here, and it must unlock.
const Set<String> deviceSignSites = {
  // Account deployment (the account's genesis).
  'lib/features/stawi/data/stawi_account_service.dart deploy',
  // ADD_KEY.
  'lib/features/stawi/data/stawi_account_service.dart addDeviceKey',
  // Money: every prepared and checked call (loans, savings, wallet).
  'lib/features/stawi/data/stawi_account_service.dart submit',
  // Room genesis.
  'lib/features/stawi/data/stawi_room_service.dart submitGenesisSignature',
  // Room calls, votes and secret-ballot commits and reveals.
  'lib/features/stawi/data/stawi_room_service.dart signedCall',
};

/// Signers that are not a device key, as `file receiver`: Matrix Olm signs
/// its own identity payloads.
const Set<String> otherSigners = {
  'lib/core/crypto/e2e_encryption_service.dart _olmAccount!',
};

/// Every `load` / `loadOrCreate` in the app, as `file method receiver.name`.
/// A device key read this way cannot sign (it is a DevicePublicKey); the list
/// keeps a new read of the key in view.
const Set<String> keyReads = {
  // The account screen's status: the key's address, nothing signed.
  'lib/features/stawi/data/stawi_account_service.dart status _keys.loadOrCreate',
  // The secret-ballot store's sealed vote, not a key.
  'lib/features/stawi/data/stawi_room_service.dart revealSecretVote _store.load',
  // SecretBallotStore reading its own sealed votes.
  'lib/features/stawi/domain/secret_ballot.dart markRevealed .load',
  'lib/features/stawi/domain/secret_ballot.dart pending .load',
};

class _Use {
  _Use(this.member, this.receiver, this.body);

  final String member;
  final String receiver;
  final AstNode? body;
}

/// Every reference to [names] (a call, with any spacing, or a tear-off) and
/// the executable it is in.
class _Uses extends RecursiveAstVisitor<void> {
  _Uses(this.names);

  final Set<String> names;
  final List<_Use> found = [];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (names.contains(node.name) &&
        node.thisOrAncestorOfType<CommentReference>() == null) {
      final parent = node.parent;
      final receiver = switch (parent) {
        MethodInvocation(:final target) when parent.methodName == node =>
          target?.toSource() ?? '',
        PropertyAccess(:final target) when parent.propertyName == node =>
          target?.toSource() ?? '',
        PrefixedIdentifier(:final prefix) when parent.identifier == node =>
          prefix.name,
        _ => '',
      };
      final (member, body) = _enclosing(node);
      found.add(_Use(member, '$receiver.${node.name}', body));
    }
    super.visitSimpleIdentifier(node);
  }

  static (String, AstNode?) _enclosing(AstNode node) {
    for (var n = node.parent; n != null; n = n.parent) {
      if (n is MethodDeclaration) return (n.name.lexeme, n.body);
      if (n is FunctionDeclaration) {
        return (n.name.lexeme, n.functionExpression.body);
      }
      // A top-level or field initializer; a local variable is inside one of
      // the above.
      if (n is VariableDeclaration &&
          (n.parent?.parent is TopLevelVariableDeclaration ||
              n.parent?.parent is FieldDeclaration)) {
        return (n.name.lexeme, n.initializer);
      }
    }
    return ('<top level>', null);
  }
}

class _Unlocks extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'unlock' && node.target != null) found = true;
    super.visitMethodInvocation(node);
  }
}

bool _unlocks(AstNode? body) {
  if (body == null) return false;
  final v = _Unlocks();
  body.accept(v);
  return v.found;
}

Map<String, CompilationUnit> _lib() => {
  for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
    if (f.path.endsWith('.dart') &&
        !f.path.endsWith('.g.dart') &&
        !f.path.endsWith('.freezed.dart'))
      f.path.replaceAll(r'\', '/'): parseString(
        content: f.readAsStringSync(),
        path: f.absolute.path,
      ).unit,
};

List<(String, _Use)> _usesOf(
  Map<String, CompilationUnit> units,
  Set<String> names,
) => [
  for (final MapEntry(key: path, value: unit) in units.entries)
    for (final use in (_Uses(names)..visitCompilationUnit(unit)).found)
      (path, use),
];

void main() {
  final units = _lib();

  test('every device-key signature is listed and unlocks first', () {
    final sites = <String>{};
    for (final (path, use) in _usesOf(units, {'sign'})) {
      final receiver = use.receiver.substring(0, use.receiver.length - 5);
      if (otherSigners.contains('$path $receiver')) continue;
      sites.add('$path ${use.member}');
      expect(
        _unlocks(use.body),
        isTrue,
        reason: '$path ${use.member} signs without the device lock',
      );
    }
    expect(sites, deviceSignSites);
  });

  test('every read of a key is listed', () {
    expect({
      for (final (path, use) in _usesOf(units, {'load', 'loadOrCreate'}))
        '$path ${use.member} ${use.receiver}',
    }, keyReads);
  });

  test('the app builds its key store only behind the device lock', () {
    final builds = <String>[];
    for (final MapEntry(key: path, value: unit) in units.entries) {
      final v = _Constructions();
      unit.accept(v);
      builds.addAll(v.found.map((args) => '$path $args'));
    }
    const production =
        'lib/features/stawi/data/device_key_store.dart '
        '(const SecureStorageDeviceKeyVault(), '
        'gate: ref.watch(signingGateProvider))';
    expect(builds, [production]);
  });

  group('the guard itself', () {
    List<String> signers(String source) => [
      for (final use in (_Uses({
        'sign',
      })..visitCompilationUnit(parseString(content: source).unit)).found)
        '${use.member} ${_unlocks(use.body)}',
    ];

    test('finds a call at any indentation and spacing', () {
      expect(
        signers('''
class A {
    static List<int>   go(K k) { return k . sign ([1]); }
}
Map<String, int> top(K k) async { await k.unlock('p', reason: 'x'); k.sign([1]); return {}; }
'''),
        ['go false', 'top true'],
      );
    });

    test('finds a tear-off', () {
      expect(
        signers('''
void f(K k) { final s = k.sign; s([1]); }
final g = (K k) => k.handle.sign;
'''),
        ['f false', 'g false'],
      );
    });
  });
}

/// The argument lists of every `DeviceKeyStore(...)` built in lib.
class _Constructions extends RecursiveAstVisitor<void> {
  final List<String> found = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null && node.methodName.name == 'DeviceKeyStore') {
      found.add(node.argumentList.toSource());
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme == 'DeviceKeyStore') {
      found.add(node.argumentList.toSource());
    }
    super.visitInstanceCreationExpression(node);
  }
}
