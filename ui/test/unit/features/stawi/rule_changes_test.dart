import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/stawi/domain/proposal_documents.dart';
import 'package:stawi/features/stawi/domain/rule_changes.dart';
import 'package:stawi/features/stawi/domain/signing_checks.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;
import 'package:stawi_finance_sdk/stawi_finance_sdk.dart';

import '../../../support/stawi_fakes.dart';

void main() {
  final all = GoRuleChange.load();

  test('the params hash and payload document are Go\'s', () {
    for (final v in all) {
      expect(
        bytesToHex0x(securityParamsHash(v.params)),
        v.json['params_hash'],
        reason: v.name,
      );
      expect(
        bytesToHex0x(securityParamsHash(v.previousParams)),
        v.json['previous_params_hash'],
        reason: v.name,
      );
      final doc = policyChangeDocument(
        custody: v.custody,
        constitutionHash: v.hex('constitution_hash'),
        financePolicyHash: v.hex('finance_policy_hash'),
        securityPolicyHash: v.hex('security_policy_hash'),
        paramsHash: securityParamsHash(v.params),
        capabilityIds: v.capabilityIds,
      );
      expect(bytesToHex0x(doc), v.json['payload'], reason: v.name);
      expect(
        bytesToHex0x(payloadHashOf(doc)),
        v.json['payload_hash'],
        reason: v.name,
      );
    }
  });

  test(
    'applying the rules on the device gives Go\'s compiled constitution',
    () {
      for (final v in all) {
        final compiled = finance.RoomPolicy()
          ..mergeFromProto3Json(jsonDecode(utf8.decode(v.documents[0])));
        expect(
          samePolicy(
            applyRuleValues(v.previousConstitution, v.values),
            compiled,
          ),
          isTrue,
          reason: v.name,
        );
        expect(samePolicy(v.previousConstitution, compiled), isFalse);
      }
    },
  );

  test('a compiled change is checked to Go\'s payload hash', () {
    for (final v in all) {
      expect(
        bytesToHex0x(
          checkedPolicyChange(
            prepared: v.prepared(),
            values: v.values,
            inForce: v.inForce,
            custody: v.custody,
          ),
        ),
        v.json['payload_hash'],
        reason: v.name,
      );
    }
  });

  group('refuses a change that is not the one chosen', () {
    final v = GoRuleChange.named('quorum_and_minimum');
    void refused(
      settlement.RoomPolicyChange c, {
      Map<String, String>? values,
      finance.PolicyVersion? inForce,
    }) => expect(
      () => checkedPolicyChange(
        prepared: v.prepared(c),
        values: values ?? v.values,
        inForce: inForce ?? v.inForce,
        custody: v.custody,
      ),
      throwsA(isA<SigningRefused>()),
    );

    test('other rule values asked for', () {
      refused(v.change, values: {...v.values, 'max_members': '40'});
      refused(v.change..ruleValues['quorum_bps'] = '7000');
    });

    test('a document that is not its hash', () {
      final c = v.change;
      c.documents[1] = Uint8List.fromList([...c.documents[1], 0x20]);
      refused(c);
    });

    test('a constitution that changes another rule', () {
      final p = applyRuleValues(v.previousConstitution, {
        ...v.values,
        'max_members': '40',
      });
      final doc = utf8.encode(jsonEncode(p.toProto3Json()));
      final c = v.change
        ..documents[0] = doc
        ..constitutionHash = keccak256(doc);
      refused(c);
    });

    test('params that move what the rules do not', () {
      refused(v.change..securityParams.freezeApprovals = 1);
      refused(v.change..securityParams.quorumBps = 7000);
      refused(v.change..previousSecurityParams.maxFeeBps = 99);
    });

    test('a policy in force other than finance\'s', () {
      refused(v.change, inForce: v.inForce..policyEpoch = Int64(2));
      refused(v.change, inForce: v.inForce..constitutionHash = Uint8List(32));
    });

    test('no compiled change at all', () {
      expect(
        () => checkedPolicyChange(
          prepared: settlement.PrepareRoomCallResponse(
            call: settlement.RoomCall(),
          ),
          values: v.values,
          inForce: v.inForce,
          custody: v.custody,
        ),
        throwsA(isA<SigningRefused>()),
      );
    });
  });

  group('rules as people type them', () {
    test('percent, days and hours to the wire and back', () {
      expect(GroupRule.quorum.parse('60'), 6000);
      expect(GroupRule.approval.parse('66.67'), 6667);
      expect(GroupRule.votingPeriod.parse('3'), 3 * 86400);
      expect(GroupRule.timelock.parse('12'), 12 * 3600);
      expect(GroupRule.withdrawalFee.parse('0.5'), 50);
      expect(GroupRule.quorum.typed(6667), '66.67');
      expect(GroupRule.withdrawalFee.typed(50), '0.5');
      expect(GroupRule.votingPeriod.show(259200), '3 days');
      expect(GroupRule.timelock.show(0), '0 hours');
    });

    test('out of range or malformed is refused', () {
      expect(() => GroupRule.quorum.parse('5'), throwsFormatException);
      expect(() => GroupRule.approval.parse('50'), throwsFormatException);
      expect(() => GroupRule.withdrawalFee.parse('2'), throwsFormatException);
      expect(() => GroupRule.votingPeriod.parse('0'), throwsFormatException);
      expect(() => GroupRule.minimumActive.parse('1.5'), throwsFormatException);
    });

    test('only the rules that change are sent', () {
      final p = GoRuleChange.named('quorum_and_minimum').previousConstitution;
      expect(
        ruleValuesOf({
          GroupRule.quorum: 6000,
          GroupRule.approval: GroupRule.approval.current(p)!,
        }, p),
        {'quorum_bps': '6000'},
      );
    });

    test('the warning counts the votes the change ends', () {
      expect(openVotesWarning(2), startsWith('2 open votes'));
      expect(openVotesWarning(1), startsWith('1 open vote '));
      expect(openVotesWarning(null), contains('proposed again'));
    });
  });
}
