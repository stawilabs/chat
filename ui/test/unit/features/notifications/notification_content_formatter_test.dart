import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/messages/domain/room_event.dart';
import 'package:stawi/features/notifications/notification_content_formatter.dart';

void main() {
  late NotificationContentFormatter formatter;

  setUp(() {
    formatter = NotificationContentFormatter();
  });

  RoomEvent createEvent({
    required RoomEventType type,
    Map<String, dynamic> content = const {},
  }) => RoomEvent(
    id: 'event-123',
    roomId: 'room-456',
    senderId: 'sender-789',
    type: type,
    content: content,
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );

  group('NotificationContentFormatter', () {
    group('title formatting', () {
      test('uses sender name for direct messages', () {
        final event = createEvent(
          type: RoomEventType.text,
          content: {'text': 'Hello'},
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.title, equals('Alice'));
        expect(result.isGroupMessage, isFalse);
      });

      test('includes room name for group messages', () {
        final event = createEvent(
          type: RoomEventType.text,
          content: {'text': 'Hello'},
        );

        final result = formatter.format(
          event: event,
          senderName: 'Alice',
          roomName: 'Team Chat',
        );

        expect(result.title, equals('Alice @ Team Chat'));
        expect(result.isGroupMessage, isTrue);
      });

      test('treats empty room name as direct message', () {
        final event = createEvent(
          type: RoomEventType.text,
          content: {'text': 'Hello'},
        );

        final result = formatter.format(
          event: event,
          senderName: 'Alice',
          roomName: '',
        );

        expect(result.title, equals('Alice'));
        expect(result.isGroupMessage, isFalse);
      });
    });

    group('text message formatting', () {
      test('shows full text when under limit', () {
        final event = createEvent(
          type: RoomEventType.text,
          content: {'text': 'Short message'},
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Short message'));
        expect(result.imageUrl, isNull);
      });

      test('truncates long text at 100 characters', () {
        final longText = 'A' * 150;
        final event = createEvent(
          type: RoomEventType.text,
          content: {'text': longText},
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body.length, equals(100));
        expect(result.body, endsWith('...'));
      });

      test('handles missing text gracefully', () {
        final event = createEvent(type: RoomEventType.text, content: {});

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals(''));
      });
    });

    group('image message formatting', () {
      test('shows "Photo" for image without caption', () {
        final event = createEvent(
          type: RoomEventType.image,
          content: {'url': 'https://example.com/image.jpg'},
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Photo'));
        expect(result.imageUrl, equals('https://example.com/image.jpg'));
      });

      test('shows caption for image with caption', () {
        final event = createEvent(
          type: RoomEventType.image,
          content: {
            'url': 'https://example.com/image.jpg',
            'caption': 'Beautiful sunset',
          },
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Photo: Beautiful sunset'));
      });

      test('extracts thumbnail URL if no main URL', () {
        final event = createEvent(
          type: RoomEventType.image,
          content: {'thumbnailUrl': 'https://example.com/thumb.jpg'},
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.imageUrl, equals('https://example.com/thumb.jpg'));
      });
    });

    group('video message formatting', () {
      test('shows "Video" for video without caption', () {
        final event = createEvent(
          type: RoomEventType.video,
          content: {'url': 'https://example.com/video.mp4'},
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Video'));
      });

      test('shows caption for video with caption', () {
        final event = createEvent(
          type: RoomEventType.video,
          content: {
            'url': 'https://example.com/video.mp4',
            'caption': 'Check this out',
          },
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Video: Check this out'));
      });

      test('extracts poster URL for thumbnail', () {
        final event = createEvent(
          type: RoomEventType.video,
          content: {'posterUrl': 'https://example.com/poster.jpg'},
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.imageUrl, equals('https://example.com/poster.jpg'));
      });
    });

    group('audio message formatting', () {
      test('shows "Voice message" without duration', () {
        final event = createEvent(
          type: RoomEventType.audio,
          content: {'url': 'https://example.com/audio.m4a'},
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Voice message'));
      });

      test('shows duration in seconds for short messages', () {
        final event = createEvent(
          type: RoomEventType.audio,
          content: {'duration': 45000}, // 45 seconds
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Voice message (45s)'));
      });

      test('shows duration in minutes and seconds for longer messages', () {
        final event = createEvent(
          type: RoomEventType.audio,
          content: {'duration': 125000}, // 2 minutes 5 seconds
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Voice message (2m 5s)'));
      });

      test('shows minutes only when no remaining seconds', () {
        final event = createEvent(
          type: RoomEventType.audio,
          content: {'duration': 120000}, // exactly 2 minutes
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Voice message (2m)'));
      });
    });

    group('file message formatting', () {
      test('shows "File" without filename', () {
        final event = createEvent(type: RoomEventType.file, content: {});

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('File'));
      });

      test('shows filename when present', () {
        final event = createEvent(
          type: RoomEventType.file,
          content: {'filename': 'document.pdf'},
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('File: document.pdf'));
      });

      test('uses name field as fallback', () {
        final event = createEvent(
          type: RoomEventType.file,
          content: {'name': 'report.xlsx'},
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('File: report.xlsx'));
      });
    });

    group('reaction message formatting', () {
      test('shows emoji when present', () {
        final event = createEvent(
          type: RoomEventType.reaction,
          content: {'emoji': '\u{1F44D}'}, // thumbs up emoji
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Reacted with \u{1F44D}'));
      });

      test('uses reaction field as fallback', () {
        final event = createEvent(
          type: RoomEventType.reaction,
          content: {'reaction': '\u{2764}'}, // heart emoji
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Reacted with \u{2764}'));
      });

      test('shows generic message without emoji', () {
        final event = createEvent(type: RoomEventType.reaction, content: {});

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Reacted to a message'));
      });
    });

    group('motion message formatting', () {
      test('shows motion title', () {
        final event = createEvent(
          type: RoomEventType.motion,
          content: {'title': 'Budget approval'},
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Motion: Budget approval'));
      });

      test('uses subject field as fallback', () {
        final event = createEvent(
          type: RoomEventType.motion,
          content: {'subject': 'New policy'},
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Motion: New policy'));
      });

      test('shows generic message without title', () {
        final event = createEvent(type: RoomEventType.motion, content: {});

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('New motion proposed'));
      });
    });

    group('vote message formatting', () {
      test('shows vote choice', () {
        final event = createEvent(
          type: RoomEventType.vote,
          content: {'vote': 'Yes'},
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Voted: Yes'));
      });

      test('shows generic message without vote', () {
        final event = createEvent(type: RoomEventType.vote, content: {});

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Cast a vote'));
      });
    });

    group('transaction message formatting', () {
      test('shows amount with currency', () {
        final event = createEvent(
          type: RoomEventType.transaction,
          content: {'amount': 100, 'currency': 'KES'},
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Transaction: KES 100'));
      });

      test('shows amount with description', () {
        final event = createEvent(
          type: RoomEventType.transaction,
          content: {
            'amount': 500,
            'currency': 'USD',
            'description': 'Monthly contribution',
          },
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(
          result.body,
          equals('Transaction: USD 500 - Monthly contribution'),
        );
      });

      test('shows description only', () {
        final event = createEvent(
          type: RoomEventType.transaction,
          content: {'description': 'Payment received'},
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Transaction: Payment received'));
      });

      test('shows generic message without details', () {
        final event = createEvent(type: RoomEventType.transaction, content: {});

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('New transaction'));
      });
    });

    group('call message formatting', () {
      test('shows incoming call for callOffer', () {
        final event = createEvent(type: RoomEventType.callOffer, content: {});

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Incoming call'));
      });

      test('shows call answered for callAnswer', () {
        final event = createEvent(type: RoomEventType.callAnswer, content: {});

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Call answered'));
      });

      test('shows call ended for callEnd', () {
        final event = createEvent(type: RoomEventType.callEnd, content: {});

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals('Call ended'));
      });
    });

    group('privacy mode (hideContent)', () {
      test('hides text message content', () {
        final event = createEvent(
          type: RoomEventType.text,
          content: {'text': 'Secret message'},
        );

        final result = formatter.format(
          event: event,
          senderName: 'Alice',
          hideContent: true,
        );

        expect(result.body, equals('New message'));
        expect(result.body, isNot(contains('Secret')));
      });

      test('hides image content', () {
        final event = createEvent(
          type: RoomEventType.image,
          content: {'caption': 'Private photo'},
        );

        final result = formatter.format(
          event: event,
          senderName: 'Alice',
          hideContent: true,
        );

        expect(result.body, equals('New photo'));
        expect(result.imageUrl, isNull);
      });

      test('hides video content', () {
        final event = createEvent(type: RoomEventType.video, content: {});

        final result = formatter.format(
          event: event,
          senderName: 'Alice',
          hideContent: true,
        );

        expect(result.body, equals('New video'));
      });

      test('hides audio duration', () {
        final event = createEvent(
          type: RoomEventType.audio,
          content: {'duration': 60000},
        );

        final result = formatter.format(
          event: event,
          senderName: 'Alice',
          hideContent: true,
        );

        expect(result.body, equals('New voice message'));
        expect(result.body, isNot(contains('60')));
      });

      test('hides file name', () {
        final event = createEvent(
          type: RoomEventType.file,
          content: {'filename': 'confidential.pdf'},
        );

        final result = formatter.format(
          event: event,
          senderName: 'Alice',
          hideContent: true,
        );

        expect(result.body, equals('New file'));
        expect(result.body, isNot(contains('confidential')));
      });

      test('hides reaction emoji', () {
        final event = createEvent(
          type: RoomEventType.reaction,
          content: {'emoji': '\u{1F60A}'}, // smiling face emoji
        );

        final result = formatter.format(
          event: event,
          senderName: 'Alice',
          hideContent: true,
        );

        expect(result.body, equals('New reaction'));
      });

      test('hides transaction amount', () {
        final event = createEvent(
          type: RoomEventType.transaction,
          content: {'amount': 1000000, 'currency': 'USD'},
        );

        final result = formatter.format(
          event: event,
          senderName: 'Alice',
          hideContent: true,
        );

        expect(result.body, equals('New transaction'));
        expect(result.body, isNot(contains('1000000')));
      });

      test('preserves sender name in privacy mode', () {
        final event = createEvent(
          type: RoomEventType.text,
          content: {'text': 'Secret'},
        );

        final result = formatter.format(
          event: event,
          senderName: 'Alice',
          roomName: 'Team Chat',
          hideContent: true,
        );

        expect(result.title, equals('Alice @ Team Chat'));
      });
    });

    group('edge cases', () {
      test('handles null content values', () {
        final event = createEvent(
          type: RoomEventType.text,
          content: {'text': null},
        );

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals(''));
      });

      test('handles empty sender name', () {
        final event = createEvent(
          type: RoomEventType.text,
          content: {'text': 'Hello'},
        );

        final result = formatter.format(event: event, senderName: '');

        expect(result.title, equals(''));
      });

      test('handles roomKey events', () {
        final event = createEvent(type: RoomEventType.roomKey, content: {});

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals(''));
      });

      test('handles callIce events', () {
        final event = createEvent(type: RoomEventType.callIce, content: {});

        final result = formatter.format(event: event, senderName: 'Alice');

        expect(result.body, equals(''));
      });
    });
  });

  group('NotificationContent', () {
    test('toString includes all fields', () {
      const content = NotificationContent(
        title: 'Test Title',
        body: 'Test Body',
        imageUrl: 'https://example.com/image.jpg',
        isGroupMessage: true,
      );

      final str = content.toString();

      expect(str, contains('title: Test Title'));
      expect(str, contains('body: Test Body'));
      expect(str, contains('imageUrl: https://example.com/image.jpg'));
      expect(str, contains('isGroupMessage: true'));
    });
  });

  group('maxNotificationTextLength', () {
    test('is defined as 100', () {
      expect(maxNotificationTextLength, equals(100));
    });
  });
}
