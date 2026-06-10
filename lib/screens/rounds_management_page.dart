import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../models/round.dart';
import 'round_detail_screen.dart';
import 'full_and_final_screen.dart';

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
      appBar: AppBar(
        title: const Text('Manage Rounds'),
        actions: [
          IconButton(
            onPressed: () => _showAddRoundDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: prov.rounds.isEmpty
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoundDetailScreen(round: round),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // Full & Final Button for cumulative totals across all rounds
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FullAndFinalScreen()), // no roundId -> all rounds
                  );
                },
                icon: const Icon(Icons.calculate),
                label: const Text('Full & Final (All Rounds)'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRoundDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final prov = context.read<BillProvider>();
    Set<String> selectedIds = {};

    if (prov.people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add people first before creating a round.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Round'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Round Name'),
                autofocus: true,
              ),
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
                          if (checked == true) {
                            selectedIds.add(person.id);
                          } else {
                            selectedIds.remove(person.id);
                          }
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
                final roundName = nameCtrl.text.trim();
                if (roundName.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter a round name')),
                  );
                  return;
                }
                if (selectedIds.isEmpty) {
                  selectedIds = prov.people.map((p) => p.id).toSet();
                }
                prov.addRound(roundName, selectedIds);
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
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