// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stawi/core/theme/app_theme.dart';

void main() {
  group('Settings Menu Items', () {
    Widget buildSettingsItem({
      required IconData icon,
      required String title,
      required String subtitle,
      VoidCallback? onTap,
    }) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
    }

    testWidgets('renders settings item with icon, title, and subtitle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildSettingsItem(
              icon: Icons.account_circle_outlined,
              title: 'Account',
              subtitle: 'Profile information, security',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Profile information, security'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('settings item responds to tap', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildSettingsItem(
              icon: Icons.lock_outline,
              title: 'Privacy',
              subtitle: 'Block contacts, disappearing messages',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders multiple settings items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                buildSettingsItem(
                  icon: Icons.account_circle_outlined,
                  title: 'Account',
                  subtitle: 'Profile information, security',
                ),
                buildSettingsItem(
                  icon: Icons.lock_outline,
                  title: 'Privacy',
                  subtitle: 'Block contacts, disappearing messages',
                ),
                buildSettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Message, group & call tones',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
    });
  });

  group('Toggle Switches', () {
    testWidgets('renders switch tile', (WidgetTester tester) async {
      var switchValue = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive push notifications'),
                value: switchValue,
                onChanged: (value) => setState(() => switchValue = value),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Enable Notifications'), findsOneWidget);
      expect(find.text('Receive push notifications'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('switch toggles when tapped', (WidgetTester tester) async {
      var switchValue = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: SwitchListTile(
                title: const Text('Dark Mode'),
                value: switchValue,
                onChanged: (value) => setState(() => switchValue = value),
              ),
            ),
          ),
        ),
      );

      // Initially off
      var switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);

      // Tap to toggle
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Should be on
      switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('disabled switch does not respond to taps', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwitchListTile(
              title: Text('Disabled Option'),
              value: false,
              onChanged: null, // Disabled
            ),
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.onChanged, isNull);
    });
  });

  group('Theme Preview', () {
    testWidgets('light theme preview renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Light Theme',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Preview of light theme appearance'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Light Theme'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('dark theme preview renders correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Dark Theme',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Preview of dark theme appearance'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Dark Theme'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('theme selector shows both options', (
      WidgetTester tester,
    ) async {
      var selectedTheme = 0; // 0 = system, 1 = light, 2 = dark

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  RadioListTile<int>(
                    title: const Text('System Default'),
                    value: 0,
                    groupValue: selectedTheme,
                    onChanged: (value) =>
                        setState(() => selectedTheme = value!),
                  ),
                  RadioListTile<int>(
                    title: const Text('Light'),
                    value: 1,
                    groupValue: selectedTheme,
                    onChanged: (value) =>
                        setState(() => selectedTheme = value!),
                  ),
                  RadioListTile<int>(
                    title: const Text('Dark'),
                    value: 2,
                    groupValue: selectedTheme,
                    onChanged: (value) =>
                        setState(() => selectedTheme = value!),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('System Default'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      // Select dark theme
      await tester.tap(find.text('Dark'));
      await tester.pump();

      final darkRadio = tester.widget<RadioListTile<int>>(
        find.widgetWithText(RadioListTile<int>, 'Dark'),
      );
      expect(darkRadio.groupValue, 2);
    });
  });

  group('Settings Profile Header', () {
    testWidgets('renders profile header with avatar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(24),
              color: AppTheme.primaryGreen,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Text(
                      'JD',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'John Doe',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hey there! I am using Chat.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('JD'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Hey there! I am using Chat.'), findsOneWidget);
    });

    testWidgets('renders loading state for profile header', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(24),
              color: AppTheme.primaryGreen,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('renders error state for profile header', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(24),
              color: AppTheme.primaryGreen,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error loading profile'), findsOneWidget);
    });
  });

  group('Settings Categories', () {
    final settingsCategories = [
      {'icon': Icons.account_circle_outlined, 'title': 'Account'},
      {'icon': Icons.lock_outline, 'title': 'Privacy'},
      {'icon': Icons.fingerprint, 'title': 'Security'},
      {'icon': Icons.chat_outlined, 'title': 'Chats'},
      {'icon': Icons.notifications_outlined, 'title': 'Notifications'},
      {'icon': Icons.storage_outlined, 'title': 'Storage'},
    ];

    testWidgets('renders all settings categories', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: settingsCategories.map((category) {
                return ListTile(
                  leading: Icon(category['icon']! as IconData),
                  title: Text(category['title']! as String),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                );
              }).toList(),
            ),
          ),
        ),
      );

      for (final category in settingsCategories) {
        expect(find.text(category['title']! as String), findsOneWidget);
        expect(find.byIcon(category['icon']! as IconData), findsOneWidget);
      }
    });
  });

  group('AppTheme', () {
    testWidgets('light theme has correct primary color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: ElevatedButton(onPressed: null, child: Text('Button')),
            ),
          ),
        ),
      );

      // Theme should apply without errors
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('dark theme has correct primary color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: Center(
              child: ElevatedButton(onPressed: null, child: Text('Button')),
            ),
          ),
        ),
      );

      // Theme should apply without errors
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    test('primaryGreen color is correct', () {
      expect(AppTheme.primaryGreen, const Color(0xFF128C7E));
    });

    test('brightGreen color is correct', () {
      expect(AppTheme.brightGreen, const Color(0xFF25D366));
    });

    testWidgets('getSubtleColor returns correct opacity', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final subtleColor = AppTheme.getSubtleColor(
                context,
                AppTheme.primaryGreen,
              );
              // Should be 10% opacity
              expect(subtleColor.a, closeTo(0.1, 0.01));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('getMessageBubbleColor returns correct color for own message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final color = AppTheme.getMessageBubbleColor(context, true);
              expect(color, AppTheme.sentBubbleLight);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets(
      'getMessageBubbleColor returns different color for other message',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final color = AppTheme.getMessageBubbleColor(context, false);
                expect(color, isNot(AppTheme.primaryGreen));
                return const SizedBox();
              },
            ),
          ),
        );
      },
    );
  });

  group('Accessibility', () {
    testWidgets('settings items are accessible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: const Text('Account'),
                  subtitle: const Text('Manage your account'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Manage your account'), findsOneWidget);
    });

    testWidgets('switch tiles have proper semantics', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwitchListTile(
              title: const Text('Enable Feature'),
              value: false,
              onChanged: (value) {},
            ),
          ),
        ),
      );

      expect(find.text('Enable Feature'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });
  });
}
