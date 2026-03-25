import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/profile/domain/user_status.dart';
import 'package:stawi/features/profile/ui/widgets/status_indicator.dart';

void main() {
  group('StatusIndicator', () {
    testWidgets('renders with correct color for online status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusIndicator(status: UserStatus.online)),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, equals(Colors.green));
    });

    testWidgets('renders with correct size', (tester) async {
      const testSize = 20.0;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusIndicator(status: UserStatus.online, size: testSize),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, equals(testSize));
      expect(container.constraints?.maxHeight, equals(testSize));
    });

    testWidgets('renders with border by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusIndicator(status: UserStatus.online)),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('renders without border when showBorder is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusIndicator(status: UserStatus.online, showBorder: false),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, isNull);
    });
  });

  group('StatusDisplay', () {
    testWidgets('shows icon and label by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusDisplay(status: UserStatus.online)),
        ),
      );

      expect(find.byIcon(UserStatus.online.icon), findsOneWidget);
      expect(find.text(UserStatus.online.label), findsOneWidget);
    });

    testWidgets('shows custom status message when provided', (tester) async {
      const customMessage = 'In a meeting';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusDisplay(
              status: UserStatus.busy,
              statusMessage: customMessage,
            ),
          ),
        ),
      );

      expect(find.text(customMessage), findsOneWidget);
      expect(find.text(UserStatus.busy.label), findsNothing);
    });

    testWidgets('hides icon when showIcon is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusDisplay(status: UserStatus.online, showIcon: false),
          ),
        ),
      );

      expect(find.byIcon(UserStatus.online.icon), findsNothing);
    });

    testWidgets('hides label when showLabel is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusDisplay(status: UserStatus.online, showLabel: false),
          ),
        ),
      );

      expect(find.text(UserStatus.online.label), findsNothing);
    });
  });

  group('StatusBadge', () {
    testWidgets('shows icon and label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusBadge(status: UserStatus.away)),
        ),
      );

      expect(find.byIcon(UserStatus.away.icon), findsOneWidget);
      expect(find.text(UserStatus.away.label), findsOneWidget);
    });

    testWidgets('has rounded container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusBadge(status: UserStatus.online)),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
    });
  });

  group('AvatarWithStatus', () {
    testWidgets('shows avatar with status indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarWithStatus(
              status: UserStatus.online,
              displayName: 'John Doe',
            ),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byType(StatusIndicator), findsOneWidget);
    });

    testWidgets('shows initials when no avatar URL', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarWithStatus(
              status: UserStatus.online,
              displayName: 'John Doe',
            ),
          ),
        ),
      );

      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('shows single initial for single-word name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarWithStatus(
              status: UserStatus.online,
              displayName: 'John',
            ),
          ),
        ),
      );

      expect(find.text('J'), findsOneWidget);
    });

    testWidgets('shows ? for empty display name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AvatarWithStatus(status: UserStatus.online, displayName: ''),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });
  });
}
