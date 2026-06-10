import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../models/round.dart';

class RoundsManagementPage extends StatefulWidget {
  const RoundsManagementPage({super.key});

  @override
  State<RoundsManagementPage> createState() => _RoundsManagementPageState();
}

class _RoundsManagementPageState extends State<RoundsManagementPage> {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BillProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Rounds'), actions: [
        IconButton(
          onPressed: () => _showAddRoundDialog(context),
          icon: const Icon(Icons.add),
        ),
      ]),
      body: prov.rounds.isEmpty
          ? const Center(child: Text('No rounds created. Tap + to add.'))
          : ListView.builder(
        itemCount: prov.rounds.length,
        itemBuilder: (ctx, i) {
          final round = prov.rounds[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              title: Text(round.name),
              subtitle: Text('Participants: ${round.participantIds.length}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(context, round.id),
              ),
              onTap: () => _editRound(context, round),
            ),
          );
        },
      ),
    );
  }

  void _showAddRoundDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final prov = context.read<BillProvider>();
    Set<String> selectedIds = {};

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Round'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Round Name')),
              const SizedBox(height: 12),
              const Text('Select participants:'),
              const SizedBox(height: 8),
              if (prov.people.isEmpty)
                const Text('No people added yet.')
              else
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: prov.people.length,
                    itemBuilder: (_, idx) {
                      final person = prov.people[idx];
                      return CheckboxListTile(
                        value: selectedIds.contains(person.id),
                        title: Text(person.name),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true)
                              selectedIds.add(person.id);
                            else
                              selectedIds.remove(person.id);
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  prov.addRound(nameCtrl.text.trim(), selectedIds);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _editRound(BuildContext context, Round round) {
    final nameCtrl = TextEditingController(text: round.name);
    final prov = context.read<BillProvider>();
    Set<String> selectedIds = Set.from(round.participantIds);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Round'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Round Name')),
              const SizedBox(height: 12),
              const Text('Select participants:'),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: prov.people.length,
                  itemBuilder: (_, idx) {
                    final person = prov.people[idx];
                    return CheckboxListTile(
                      value: selectedIds.contains(person.id),
                      title: Text(person.name),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true)
                            selectedIds.add(person.id);
                          else
                            selectedIds.remove(person.id);
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                prov.updateRound(round.id, name: nameCtrl.text.trim(), participantIds: selectedIds);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String roundId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Round'),
        content: const Text('Food items assigned to this round will become unassigned. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context.read<BillProvider>().deleteRound(roundId);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}