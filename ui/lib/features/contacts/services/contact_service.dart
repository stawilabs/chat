import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final contactServiceProvider = Provider<ContactService>(
  (ref) => ContactService(),
);

final contactsProvider = FutureProvider<List<fc.Contact>>((ref) async {
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
  Future<List<fc.Contact>> getContacts() async {
    final status = await fc.FlutterContacts.permissions.request(fc.PermissionType.read);
    if (status == fc.PermissionStatus.granted || status == fc.PermissionStatus.limited) {
      return fc.FlutterContacts.getAll(properties: {
        fc.ContactProperty.name,
        fc.ContactProperty.phone,
        fc.ContactProperty.email,
        fc.ContactProperty.organization,
        fc.ContactProperty.photoThumbnail,
      });
    }
    return [];
  }

  // Note: Backend sync will be implemented to find which contacts are on the app
  // Future<List<User>> syncContacts(List<Contact> contacts) async { ... }
}
