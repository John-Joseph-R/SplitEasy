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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Rounds'),
        actions: [
          IconButton(
            onPressed: () => _showAddRoundDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: prov.rounds.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No rounds yet', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _showAddRoundDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create a round'),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: prov.rounds.length,
        itemBuilder: (ctx, i) {
          final round = prov.rounds[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                foregroundColor: const Color(0xFF4F46E5),
                child: Text(round.name.isNotEmpty ? round.name[0].toUpperCase() : 'R'),
              ),
              title: Text(round.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${round.participantIds.length} participant${round.participantIds.length == 1 ? '' : 's'}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(context, round.id),
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => RoundDetailScreen(round: round)));
              },
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FullAndFinalScreen()));
              },
              icon: const Icon(Icons.calculate),
              label: const Text('Full & Final (All Rounds)'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddRoundDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final prov = context.read<BillProvider>();
    Set<String> selectedIds = {};

    if (prov.people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add people first before creating a round')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          bool allSelected = prov.people.isNotEmpty && prov.people.every((p) => selectedIds.contains(p.id));

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: const Text('New Round'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Round name'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('Participants', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: allSelected,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        selectedIds = prov.people.map((p) => p.id).toSet();
                      } else {
                        selectedIds.clear();
                      }
                    });
                  },
                  title: const Text('Select all'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
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
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
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
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  if (selectedIds.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Select at least one participant')));
                    return;
                  }
                  prov.addRound(name, selectedIds);
                  Navigator.pop(ctx);
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String roundId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Delete round?'),
        content: const Text('Food items in this round will become unassigned.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context.read<BillProvider>().deleteRound(roundId);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}