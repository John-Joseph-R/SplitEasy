import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/bill_provider.dart';

class PersonChip extends StatelessWidget {
  final Person person;
  final bool deletable;
  const PersonChip({super.key, required this.person, this.deletable = true});

  @override
  Widget build(BuildContext context) {
    if (deletable) {
      return GestureDetector(
        onLongPress: () => _showEditDialog(context),
        child: InputChip(
          label: Text(person.name),
          onDeleted: () => context.read<BillProvider>().removePerson(person.id),
        ),
      );
    } else {
      // Non‑deletable version for round detail screen
      return Chip(
        label: Text(person.name),
        avatar: const Icon(Icons.person, size: 16),
      );
    }
  }

  void _showEditDialog(BuildContext context) {
    final ctrl = TextEditingController(text: person.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Person"),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(
            onPressed: () {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                context.read<BillProvider>().editPerson(person.id, newName);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }
}