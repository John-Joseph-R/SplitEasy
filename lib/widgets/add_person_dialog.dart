import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../screens/contact_picker_page.dart';

class AddPersonDialog extends StatefulWidget {
  const AddPersonDialog({super.key});

  @override
  State<AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends State<AddPersonDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Add person'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(hintText: 'Name'),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final contact = await Navigator.push(context, MaterialPageRoute(builder: (_) => ContactPickerPage()));
              if (contact != null) setState(() => _ctrl.text = contact.displayName);
            },
            icon: const Icon(Icons.contacts),
            label: const Text('Pick from contacts'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final name = _ctrl.text.trim();
            if (name.isEmpty) return;
            context.read<BillProvider>().addPerson(name);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}