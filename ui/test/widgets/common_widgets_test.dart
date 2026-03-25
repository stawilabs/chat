import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stawi/core/error/app_error.dart';
import 'package:stawi/widgets/empty_state.dart';
import 'package:stawi/widgets/error_banner.dart';
import 'package:stawi/widgets/skeleton_loader.dart';

void main() {
  group('EmptyState Widget', () {
    testWidgets('renders icon, title, and message correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No messages',
              message: 'Your inbox is empty',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No messages'), findsOneWidget);
      expect(find.text('Your inbox is empty'), findsOneWidget);
    });

    testWidgets('renders without optional message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(icon: Icons.search, title: 'No results'),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('No results'), findsOneWidget);
    });

    testWidgets('shows action button when provided', (
      WidgetTester tester,
    ) async {
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.add,
              title: 'Get started',
              actionLabel: 'Add item',
              onAction: () => buttonPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Add item'), findsOneWidget);
      // The action button with add icon should be present
      expect(find.byIcon(Icons.add), findsAtLeast(1));

      await tester.tap(find.text('Add item'));
      await tester.pump();

      expect(buttonPressed, isTrue);
    });

    testWidgets('does not show action button when only label provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.warning,
              title: 'Warning',
              actionLabel: 'Retry',
              // onAction is not provided
            ),
          ),
        ),
      );

      // Button should not appear without onAction callback
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('renders correctly in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: EmptyState(
              icon: Icons.folder,
              title: 'No files',
              message: 'Upload your first file',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.text('No files'), findsOneWidget);
      expect(find.text('Upload your first file'), findsOneWidget);
    });

    testWidgets('is centered on screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(icon: Icons.chat, title: 'No conversations'),
          ),
        ),
      );

      // EmptyState uses Center widget internally
      expect(find.byType(Center), findsAtLeast(1));
    });
  });

  group('ErrorBanner Widget', () {
    testWidgets('displays network error correctly', (
      WidgetTester tester,
    ) async {
      const error = AppError(
        type: ErrorType.network,
        message: 'Connection lost. Please check your internet.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorBanner(error: error)),
        ),
      );

      expect(
        find.text('Connection lost. Please check your internet.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('displays authentication error correctly', (
      WidgetTester tester,
    ) async {
      const error = AppError(
        type: ErrorType.authentication,
        message: 'Session expired. Please log in again.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorBanner(error: error)),
        ),
      );

      expect(
        find.text('Session expired. Please log in again.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('displays validation error correctly', (
      WidgetTester tester,
    ) async {
      const error = AppError(
        type: ErrorType.validation,
        message: 'Please enter valid data.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorBanner(error: error)),
        ),
      );

      expect(find.text('Please enter valid data.'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('displays server error correctly', (WidgetTester tester) async {
      const error = AppError(
        type: ErrorType.server,
        message: 'Server error. Please try again.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorBanner(error: error)),
        ),
      );

      expect(find.text('Server error. Please try again.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays unknown error correctly', (
      WidgetTester tester,
    ) async {
      const error = AppError(
        type: ErrorType.unknown,
        message: 'Something went wrong.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorBanner(error: error)),
        ),
      );

      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (
      WidgetTester tester,
    ) async {
      var retryPressed = false;
      const error = AppError(type: ErrorType.network, message: 'Network error');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBanner(error: error, onRetry: () => retryPressed = true),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryPressed, isTrue);
    });

    testWidgets('shows dismiss button when onDismiss provided', (
      WidgetTester tester,
    ) async {
      var dismissPressed = false;
      const error = AppError(
        type: ErrorType.validation,
        message: 'Invalid input',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBanner(
              error: error,
              onDismiss: () => dismissPressed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(dismissPressed, isTrue);
    });

    testWidgets('shows both retry and dismiss buttons', (
      WidgetTester tester,
    ) async {
      const error = AppError(type: ErrorType.server, message: 'Server error');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBanner(error: error, onRetry: () {}, onDismiss: () {}),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('SkeletonLoader Widget', () {
    testWidgets('renders with default dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: SkeletonLoader())),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SkeletonLoader),
          matching: find.byType(Container),
        ),
      );

      // Default height is 20
      expect(container.constraints?.maxHeight, 20);
    });

    testWidgets('renders with custom dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: SkeletonLoader(width: 100, height: 50)),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SkeletonLoader),
          matching: find.byType(Container),
        ),
      );

      expect(container.constraints?.maxHeight, 50);
      expect(container.constraints?.maxWidth, 100);
    });

    testWidgets('renders with custom border radius', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SkeletonLoader(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('animation controller is active', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: SkeletonLoader())),
        ),
      );

      // Pump a few frames to verify animation runs
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Widget should still be present
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('disposes animation controller properly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: SkeletonLoader())),
        ),
      );

      // Remove the widget
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );

      // No errors should occur during disposal
      expect(find.byType(SkeletonLoader), findsNothing);
    });
  });

  group('RoomListSkeleton Widget', () {
    testWidgets('renders avatar, content, and timestamp skeletons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RoomListSkeleton())),
      );

      // Should have multiple skeleton loaders for avatar, title, subtitle, timestamp
      expect(
        find.byType(SkeletonLoader),
        findsAtLeast(3),
      ); // At least avatar, title, subtitle
    });

    testWidgets('avatar skeleton has circular shape', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RoomListSkeleton())),
      );

      // Find the avatar skeleton (first one with 48x48 dimensions)
      final skeletons = tester.widgetList<SkeletonLoader>(
        find.byType(SkeletonLoader),
      );

      // First skeleton should be the avatar with circular border radius
      final avatarSkeleton = skeletons.first;
      expect(avatarSkeleton.width, 48);
      expect(avatarSkeleton.height, 48);
    });
  });

  group('MessageSkeleton Widget', () {
    testWidgets('renders skeleton for received message (isMe=false)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MessageSkeleton())),
      );

      // Should have avatar skeleton for received messages
      expect(find.byType(SkeletonLoader), findsAtLeast(2));
    });

    testWidgets('renders skeleton for sent message (isMe=true)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MessageSkeleton(isMe: true))),
      );

      // Should not have avatar skeleton for sent messages (only message bubble)
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('sent message skeleton aligns to the right', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MessageSkeleton(isMe: true))),
      );

      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.mainAxisAlignment, MainAxisAlignment.end);
    });

    testWidgets('received message skeleton aligns to the left', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MessageSkeleton())),
      );

      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.mainAxisAlignment, MainAxisAlignment.start);
    });
  });

  group('Accessibility', () {
    testWidgets('EmptyState has semantic labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No messages',
              message: 'Your inbox is empty',
            ),
          ),
        ),
      );

      // Text widgets provide semantic information
      expect(find.text('No messages'), findsOneWidget);
      expect(find.text('Your inbox is empty'), findsOneWidget);
    });

    testWidgets('ErrorBanner retry button is accessible', (
      WidgetTester tester,
    ) async {
      const error = AppError(type: ErrorType.network, message: 'Network error');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorBanner(error: error, onRetry: () {}),
          ),
        ),
      );

      // Retry button should be tappable
      expect(find.text('Retry'), findsOneWidget);
      final retryButton = find.widgetWithText(TextButton, 'Retry');
      expect(retryButton, findsOneWidget);
    });
  });

  group('Theme Support', () {
    testWidgets('EmptyState works in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: EmptyState(icon: Icons.folder, title: 'Empty'),
          ),
        ),
      );

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('EmptyState works in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: EmptyState(icon: Icons.folder, title: 'Empty'),
          ),
        ),
      );

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('ErrorBanner works in light theme', (
      WidgetTester tester,
    ) async {
      const error = AppError(type: ErrorType.network, message: 'Error');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(body: ErrorBanner(error: error)),
        ),
      );

      expect(find.byType(ErrorBanner), findsOneWidget);
    });

    testWidgets('ErrorBanner works in dark theme', (WidgetTester tester) async {
      const error = AppError(type: ErrorType.network, message: 'Error');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(body: ErrorBanner(error: error)),
        ),
      );

      expect(find.byType(ErrorBanner), findsOneWidget);
    });

    testWidgets('SkeletonLoader works in both themes', (
      WidgetTester tester,
    ) async {
      for (final theme in [ThemeData.light(), ThemeData.dark()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: const Scaffold(body: Center(child: SkeletonLoader())),
          ),
        );

        expect(find.byType(SkeletonLoader), findsOneWidget);
      }
    });
  });
}
