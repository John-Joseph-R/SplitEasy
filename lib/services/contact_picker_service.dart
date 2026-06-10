import 'package:flutter_contacts/flutter_contacts.dart';

class ContactPickerService {
  static Future<List<Contact>> getAllContacts() async {
    if (!await FlutterContacts.requestPermission()) {
      return [];
    }

    return await FlutterContacts.getContacts(withProperties: true);
  }
}
