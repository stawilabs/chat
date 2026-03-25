import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final contactServiceProvider = Provider<ContactService>(
  (ref) => ContactService(),
);

final contactsProvider = FutureProvider<List<Contact>>((ref) async {
  final service = ref.watch(contactServiceProvider);
  return service.getContacts();
});

/// Provider that checks if contact permission is granted.
/// Returns true if permission is granted, false otherwise.
final contactPermissionGrantedProvider = FutureProvider<bool>((ref) async {
  final status = await Permission.contacts.status;
  return status.isGranted;
});

class ContactService {
  Future<List<Contact>> getContacts() async {
    if (await FlutterContacts.requestPermission()) {
      return FlutterContacts.getContacts(withProperties: true, withPhoto: true);
    }
    return [];
  }

  // Note: Backend sync will be implemented to find which contacts are on the app
  // Future<List<User>> syncContacts(List<Contact> contacts) async { ... }
}
