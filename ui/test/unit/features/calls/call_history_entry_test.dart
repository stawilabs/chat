import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/calls/domain/call_history_entry.dart';

void main() {
  group('CallType', () {
    test('has exactly 2 values', () {
      expect(CallType.values.length, equals(2));
    });

    test('audio has correct properties', () {
      const type = CallType.audio;
      expect(type.value, equals(0));
      expect(type.label, equals('Voice Call'));
      expect(type.icon, equals(Icons.phone));
    });

    test('video has correct properties', () {
      const type = CallType.video;
      expect(type.value, equals(1));
      expect(type.label, equals('Video Call'));
      expect(type.icon, equals(Icons.videocam));
    });

    test('fromValue returns correct type', () {
      expect(CallType.fromValue(0), equals(CallType.audio));
      expect(CallType.fromValue(1), equals(CallType.video));
      expect(CallType.fromValue(99), equals(CallType.audio)); // fallback
    });
  });

  group('CallDirection', () {
    test('has exactly 2 values', () {
      expect(CallDirection.values.length, equals(2));
    });

    test('outgoing has correct properties', () {
      const dir = CallDirection.outgoing;
      expect(dir.value, equals(0));
      expect(dir.label, equals('Outgoing'));
    });

    test('incoming has correct properties', () {
      const dir = CallDirection.incoming;
      expect(dir.value, equals(1));
      expect(dir.label, equals('Incoming'));
    });

    test('fromValue returns correct direction', () {
      expect(CallDirection.fromValue(0), equals(CallDirection.outgoing));
      expect(CallDirection.fromValue(1), equals(CallDirection.incoming));
      expect(
        CallDirection.fromValue(99),
        equals(CallDirection.outgoing),
      ); // fallback
    });
  });

  group('CallStatus', () {
    test('has exactly 5 values', () {
      expect(CallStatus.values.length, equals(5));
    });

    test('missed has correct properties', () {
      const status = CallStatus.missed;
      expect(status.value, equals(0));
      expect(status.label, equals('Missed'));
      expect(status.color, equals(Colors.red));
    });

    test('answered has correct properties', () {
      const status = CallStatus.answered;
      expect(status.value, equals(1));
      expect(status.label, equals('Answered'));
      expect(status.color, equals(Colors.green));
    });

    test('fromValue returns correct status', () {
      expect(CallStatus.fromValue(0), equals(CallStatus.missed));
      expect(CallStatus.fromValue(1), equals(CallStatus.answered));
      expect(CallStatus.fromValue(2), equals(CallStatus.declined));
      expect(CallStatus.fromValue(3), equals(CallStatus.busy));
      expect(CallStatus.fromValue(4), equals(CallStatus.failed));
      expect(CallStatus.fromValue(99), equals(CallStatus.missed)); // fallback
    });
  });

  group('CallHistoryEntry', () {
    const baseEntry = CallHistoryEntry(
      id: 1,
      roomId: 'room-123',
      callerId: 'caller-123',
      recipientId: 'recipient-456',
      callType: CallType.audio,
      direction: CallDirection.outgoing,
      status: CallStatus.answered,
      startedAt: 1700000000000,
      answeredAt: 1700000005000,
      endedAt: 1700000125000,
      duration: 120,
      callerName: 'John Doe',
      recipientName: 'Jane Smith',
    );

    test('creates entry with all fields', () {
      expect(baseEntry.id, equals(1));
      expect(baseEntry.roomId, equals('room-123'));
      expect(baseEntry.callerId, equals('caller-123'));
      expect(baseEntry.recipientId, equals('recipient-456'));
      expect(baseEntry.callType, equals(CallType.audio));
      expect(baseEntry.direction, equals(CallDirection.outgoing));
      expect(baseEntry.status, equals(CallStatus.answered));
      expect(baseEntry.duration, equals(120));
    });

    group('computed properties', () {
      test('isMissed returns true for missed calls', () {
        final missedCall = baseEntry.copyWith(status: CallStatus.missed);
        expect(missedCall.isMissed, isTrue);
        expect(baseEntry.isMissed, isFalse);
      });

      test('isIncoming returns true for incoming calls', () {
        final incomingCall = baseEntry.copyWith(
          direction: CallDirection.incoming,
        );
        expect(incomingCall.isIncoming, isTrue);
        expect(baseEntry.isIncoming, isFalse);
      });

      test('isOutgoing returns true for outgoing calls', () {
        expect(baseEntry.isOutgoing, isTrue);
        final incomingCall = baseEntry.copyWith(
          direction: CallDirection.incoming,
        );
        expect(incomingCall.isOutgoing, isFalse);
      });

      test('wasAnswered returns true for answered calls', () {
        expect(baseEntry.wasAnswered, isTrue);
        final missedCall = baseEntry.copyWith(status: CallStatus.missed);
        expect(missedCall.wasAnswered, isFalse);
      });

      test('formattedDuration formats correctly', () {
        expect(baseEntry.formattedDuration, equals('2:00'));

        final shortCall = baseEntry.copyWith(duration: 65);
        expect(shortCall.formattedDuration, equals('1:05'));

        final noCall = baseEntry.copyWith(duration: 0);
        expect(noCall.formattedDuration, equals(''));
      });

      test('startedAtDateTime converts timestamp correctly', () {
        final dateTime = baseEntry.startedAtDateTime;
        expect(
          dateTime,
          equals(DateTime.fromMillisecondsSinceEpoch(1700000000000)),
        );
      });

      test('otherPartyName returns correct name for direction', () {
        // Outgoing call - other party is recipient
        expect(baseEntry.otherPartyName, equals('Jane Smith'));

        // Incoming call - other party is caller
        final incomingCall = baseEntry.copyWith(
          direction: CallDirection.incoming,
        );
        expect(incomingCall.otherPartyName, equals('John Doe'));
      });

      test('otherPartyId returns correct ID for direction', () {
        // Outgoing call - other party is recipient
        expect(baseEntry.otherPartyId, equals('recipient-456'));

        // Incoming call - other party is caller
        final incomingCall = baseEntry.copyWith(
          direction: CallDirection.incoming,
        );
        expect(incomingCall.otherPartyId, equals('caller-123'));
      });
    });

    group('icon', () {
      test('returns call_missed for missed incoming calls', () {
        final missedIncoming = baseEntry.copyWith(
          direction: CallDirection.incoming,
          status: CallStatus.missed,
        );
        expect(missedIncoming.icon, equals(Icons.call_missed));
      });

      test('returns call_received for answered incoming voice calls', () {
        final incomingVoice = baseEntry.copyWith(
          direction: CallDirection.incoming,
          callType: CallType.audio,
        );
        expect(incomingVoice.icon, equals(Icons.call_received));
      });

      test('returns videocam for answered incoming video calls', () {
        final incomingVideo = baseEntry.copyWith(
          direction: CallDirection.incoming,
          callType: CallType.video,
        );
        expect(incomingVideo.icon, equals(Icons.videocam));
      });

      test('returns call_made for outgoing voice calls', () {
        expect(baseEntry.icon, equals(Icons.call_made));
      });

      test('returns videocam for outgoing video calls', () {
        final outgoingVideo = baseEntry.copyWith(callType: CallType.video);
        expect(outgoingVideo.icon, equals(Icons.videocam));
      });
    });

    group('color', () {
      test('returns red for missed calls', () {
        final missedCall = baseEntry.copyWith(status: CallStatus.missed);
        expect(missedCall.color, equals(Colors.red));
      });

      test('returns blue for incoming answered calls', () {
        final incomingCall = baseEntry.copyWith(
          direction: CallDirection.incoming,
        );
        expect(incomingCall.color, equals(Colors.blue));
      });

      test('returns green for outgoing calls', () {
        expect(baseEntry.color, equals(Colors.green));
      });
    });

    test('copyWith creates copy with updated fields', () {
      final copy = baseEntry.copyWith(duration: 300, status: CallStatus.missed);

      expect(copy.duration, equals(300));
      expect(copy.status, equals(CallStatus.missed));
      // Other fields unchanged
      expect(copy.id, equals(baseEntry.id));
      expect(copy.roomId, equals(baseEntry.roomId));
      expect(copy.callerId, equals(baseEntry.callerId));
    });
  });
}
