import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../services/contact_picker_service.dart';

class ContactPickerPage extends StatefulWidget {
  @override
  State<ContactPickerPage> createState() => _ContactPickerPageState();
}

class _ContactPickerPageState extends State<ContactPickerPage> {
  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  void loadContacts() async {
    final list = await ContactPickerService.getAllContacts();
    setState(() {
      contacts = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Contact")),
      body: contacts.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final c = contacts[index];
          return ListTile(
            title: Text(c.displayName),
            subtitle: Text(
              c.phones.isNotEmpty ? c.phones.first.number : 'No number',
            ),
            onTap: () => Navigator.pop(context, c),
          );
        },
      ),
    );
  }
}
