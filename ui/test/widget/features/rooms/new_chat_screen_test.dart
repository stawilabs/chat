import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/contacts/data/roster_repository.dart';
import 'package:stawi/features/contacts/services/contact_service.dart';
import 'package:stawi/features/rooms/ui/group_details_screen.dart';
import 'package:stawi/features/rooms/ui/new_chat_screen.dart';

void main() {
  RosterEntry contact(String id, String name) => RosterEntry(
    id: id,
    contactId: 'c-$id',
    profileId: 'p-$id',
    contactType: RosterContactType.msisdn,
    contactDetail: '+25670000000$id',
    displayName: name,
  );

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contactPermissionGrantedProvider.overrideWith((ref) async => true),
          rosterStreamProvider.overrideWith(
            (ref) =>
                Stream.value([contact('1', 'Amina'), contact('2', 'Baraka')]),
          ),
        ],
        child: const MaterialApp(home: NewChatScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a group can be made with one other person', (tester) async {
    await pump(tester);
    expect(find.byKey(const Key('new-chat-create-group')), findsNothing);
    await tester.tap(find.text('Amina'));
    await tester.pumpAndSettle();
    // One contact: a direct chat, or a two-person group (a Stawi room needs
    // a group).
    expect(find.text('Chat'), findsOneWidget);
    expect(find.byKey(const Key('new-chat-create-group')), findsOneWidget);
    await tester.tap(find.byKey(const Key('new-chat-create-group')));
    await tester.pumpAndSettle();
    final details = tester.widget<GroupDetailsScreen>(
      find.byType(GroupDetailsScreen),
    );
    expect(details.selectedContacts.map((c) => c.displayName), ['Amina']);
  });
}
