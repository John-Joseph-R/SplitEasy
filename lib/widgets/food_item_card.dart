import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../providers/bill_provider.dart';
import '../models/round.dart';
class FoodItemCard extends StatelessWidget {
  final FoodItem food;
  const FoodItemCard({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BillProvider>();

    Future<Round?> _getRound(BuildContext context, String roundId) async {
      final prov = context.read<BillProvider>();
      return prov.rounds.firstWhere((r) => r.id == roundId, orElse: () => Round(id: '', name: '', participantIds: {}));
    }
    // Assigned people names (default = all people)
    final assignedNames = food.assigned.isEmpty
        ? prov.people.map((p) => p.name).toList()
        : prov.people
        .where((p) => food.assigned.contains(p.id))
        .map((p) => p.name)
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text('₹${food.price.toStringAsFixed(2)} × ${food.qty} = ₹${(food.price * food.qty).toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            if (food.isRoundBased && food.roundNumber != null)
              FutureBuilder<Round?>(
                future: _getRound(context, food.roundNumber as String),
                builder: (ctx, snapshot) {
                  final roundName = snapshot.data?.name ?? 'Unknown round';
                  return Chip(label: Text('Round: $roundName'));
                },
              )
            else
              Wrap(
                spacing: 6,
                children: assignedNames.map((n) => Chip(label: Text(n))).toList(),
              ),
          ],
        ),

        /// Edit + Assign buttons
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.group),
              onPressed: () => _openAssign(context, food),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _openEdit(context, food),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------
  // ASSIGN PEOPLE TO FOOD
  // ------------------------------
  void _openAssign(BuildContext context, FoodItem f) {
    showDialog(
      context: context,
      builder: (_) {
        final prov = context.read<BillProvider>();

        /// Make a local editable copy
        final localAssigned = Set<String>.from(f.assigned);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Assign: ${f.name}'),
              content: SizedBox(
                width: double.maxFinite,
                child: prov.people.isEmpty
                    ? const Text('Add people first.')
                    : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: prov.people.map((p) {
                    final isAssigned = localAssigned.contains(p.id);
                    return CheckboxListTile(
                      value: isAssigned,
                      title: Text(p.name),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            localAssigned.add(p.id);
                          } else {
                            localAssigned.remove(p.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final provider = context.read<BillProvider>();

                    /// If no assignment selected → assign to all
                    final result = localAssigned.isEmpty && provider.people.isNotEmpty
                        ? provider.people.map((p) => p.id).toSet()
                        : localAssigned;

                    provider.assignFood(f.id, result);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ------------------------------
  // EDIT FOOD
  // ------------------------------
  void _openEdit(BuildContext context, FoodItem f) {
    final nameCtrl = TextEditingController(text: f.name);
    final priceCtrl = TextEditingController(text: f.price.toString());
    final qtyCtrl = TextEditingController(text: f.qty.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Food'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: priceCtrl,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price'),
              ),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Qty'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final nm = nameCtrl.text.trim();
              final pr = double.tryParse(priceCtrl.text.trim()) ?? f.price;
              final qt = int.tryParse(qtyCtrl.text.trim()) ?? f.qty;

              context.read<BillProvider>().editFood(
                f.id,
                name: nm,
                price: pr,
                qty: qt,
              );

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
