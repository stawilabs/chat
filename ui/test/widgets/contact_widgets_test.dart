import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stawi/widgets/cached_profile_avatar.dart';

void main() {
  group('CachedProfileAvatar Widget', () {
    testWidgets('shows initials when no image URL provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: CachedProfileAvatar(name: 'John Doe')),
            ),
          ),
        ),
      );

      // Should show first letter of first and last name
      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('shows single initial for single name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: CachedProfileAvatar(name: 'Alice')),
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('shows question mark for empty name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: CachedProfileAvatar(name: '')),
            ),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('shows question mark for null name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: Center(child: CachedProfileAvatar())),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('renders with custom radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: CachedProfileAvatar(name: 'Test', radius: 40),
              ),
            ),
          ),
        ),
      );

      final circleAvatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar).first,
      );
      expect(circleAvatar.radius, 40);
    });

    testWidgets('renders with default radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: CachedProfileAvatar(name: 'Test')),
            ),
          ),
        ),
      );

      final circleAvatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar).first,
      );
      expect(circleAvatar.radius, 20); // Default radius
    });

    testWidgets('applies custom background color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: CachedProfileAvatar(
                  name: 'Test',
                  backgroundColor: Colors.red,
                ),
              ),
            ),
          ),
        ),
      );

      final circleAvatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar).first,
      );
      expect(circleAvatar.backgroundColor, Colors.red);
    });

    testWidgets('applies custom foreground color', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: CachedProfileAvatar(
                  name: 'Test',
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );

      // Find the text widget and check its color
      final text = tester.widget<Text>(find.text('T'));
      expect(text.style?.color, Colors.white);
    });

    testWidgets('handles onTap callback', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: CachedProfileAvatar(
                  name: 'Test',
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CachedProfileAvatar));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('is not tappable without onTap callback', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: CachedProfileAvatar(name: 'Test')),
            ),
          ),
        ),
      );

      // GestureDetector should not be present without onTap
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('handles names with multiple spaces', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: CachedProfileAvatar(name: '  Jane   Doe  ')),
            ),
          ),
        ),
      );

      // Should handle extra spaces and show initials
      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('handles names with three or more parts', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: CachedProfileAvatar(name: 'John Michael Doe'),
              ),
            ),
          ),
        ),
      );

      // Should use first and second name initials
      expect(find.text('JM'), findsOneWidget);
    });

    testWidgets('initials are uppercase', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: CachedProfileAvatar(name: 'john doe')),
            ),
          ),
        ),
      );

      expect(find.text('JD'), findsOneWidget);
    });
  });

  group('CachedProfileAvatarGroup Widget', () {
    testWidgets('renders multiple avatars', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CachedProfileAvatarGroup(
                imageUrls: [null, null, null],
                names: ['Alice', 'Bob', 'Charlie'],
              ),
            ),
          ),
        ),
      );

      // Should show initials for all three
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('limits displayed avatars to maxAvatars', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CachedProfileAvatarGroup(
                imageUrls: [null, null, null, null, null],
                names: ['A', 'B', 'C', 'D', 'E'],
              ),
            ),
          ),
        ),
      );

      // Should only show 3 avatars plus overflow indicator
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('shows overflow count for extra avatars', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CachedProfileAvatarGroup(
                imageUrls: [null, null, null, null, null, null],
                names: ['A', 'B', 'C', 'D', 'E', 'F'],
                maxAvatars: 2,
              ),
            ),
          ),
        ),
      );

      // Should show +4 for the remaining avatars
      expect(find.text('+4'), findsOneWidget);
    });

    testWidgets('renders with custom radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CachedProfileAvatarGroup(
                imageUrls: [null, null],
                names: ['Alice', 'Bob'],
                radius: 24,
              ),
            ),
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(CachedProfileAvatarGroup), findsOneWidget);
    });

    testWidgets('renders with custom overlap', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CachedProfileAvatarGroup(
                imageUrls: [null, null],
                names: ['Alice', 'Bob'],
                overlap: 12,
              ),
            ),
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(CachedProfileAvatarGroup), findsOneWidget);
    });

    testWidgets('handles empty lists', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: CachedProfileAvatarGroup(imageUrls: [])),
          ),
        ),
      );

      // Widget should render without errors
      expect(find.byType(CachedProfileAvatarGroup), findsOneWidget);
    });

    testWidgets('handles single avatar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CachedProfileAvatarGroup(
                imageUrls: [null],
                names: ['Solo'],
              ),
            ),
          ),
        ),
      );

      expect(find.text('S'), findsOneWidget);
    });
  });

  group('Contact List Item Patterns', () {
    // Tests for common contact display patterns

    testWidgets('contact avatar with initials renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              leading: const CircleAvatar(child: Text('JD')),
              title: const Text('John Doe'),
              subtitle: const Text('+1 234 567 8900'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('JD'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('+1 234 567 8900'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('contact with verified badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              leading: const CircleAvatar(child: Text('A')),
              title: const Row(
                children: [
                  Text('Alice Smith'),
                  SizedBox(width: 4),
                  Icon(Icons.verified, size: 16, color: Colors.blue),
                ],
              ),
              subtitle: const Text('alice@example.com'),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('contact selection checkbox', (WidgetTester tester) async {
      var selected = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: CheckboxListTile(
                secondary: const CircleAvatar(child: Text('B')),
                title: const Text('Bob Johnson'),
                value: selected,
                onChanged: (value) => setState(() => selected = value ?? false),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Bob Johnson'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Checkbox should be checked
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('contact with status indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              leading: Stack(
                children: [
                  const CircleAvatar(child: Text('C')),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              title: const Text('Carol Davis'),
              subtitle: const Text('Online'),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Carol Davis'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
    });
  });

  group('Theme Support', () {
    testWidgets('CachedProfileAvatar renders in light theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(
              body: Center(child: CachedProfileAvatar(name: 'Test User')),
            ),
          ),
        ),
      );

      expect(find.text('TU'), findsOneWidget);
    });

    testWidgets('CachedProfileAvatar renders in dark theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: Center(child: CachedProfileAvatar(name: 'Test User')),
            ),
          ),
        ),
      );

      expect(find.text('TU'), findsOneWidget);
    });

    testWidgets('CachedProfileAvatarGroup renders in light theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: Center(
              child: CachedProfileAvatarGroup(
                imageUrls: [null, null],
                names: ['Alice', 'Bob'],
              ),
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('CachedProfileAvatarGroup renders in dark theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: Center(
              child: CachedProfileAvatarGroup(
                imageUrls: [null, null],
                names: ['Alice', 'Bob'],
              ),
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });

  group('Accessibility', () {
    testWidgets('avatar is accessible for screen readers', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: CachedProfileAvatar(name: 'John Doe')),
            ),
          ),
        ),
      );

      // CircleAvatar should be present
      expect(find.byType(CircleAvatar), findsOneWidget);

      // Text initials should be readable
      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('tappable avatar has gesture detector', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: CachedProfileAvatar(name: 'Jane', onTap: () {}),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget);
    });
  });

  group('Edge Cases', () {
    testWidgets('handles unicode names', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: CachedProfileAvatar(name: 'Jean-Pierre Dupont'),
              ),
            ),
          ),
        ),
      );

      // Should use first letter of each word part
      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('handles very long names', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: CachedProfileAvatar(
                  name: 'Extremely Long First Name Very Long Last Name',
                ),
              ),
            ),
          ),
        ),
      );

      // Should only show first two initials
      expect(find.text('EL'), findsOneWidget);
    });

    testWidgets('handles names starting with numbers', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(child: CachedProfileAvatar(name: '123 Test')),
            ),
          ),
        ),
      );

      // Should use what's available
      expect(find.text('1T'), findsOneWidget);
    });
  });
}
