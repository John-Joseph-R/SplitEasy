import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../models/round.dart';
import '../providers/bill_provider.dart';

class FoodItemCard extends StatelessWidget {
  final FoodItem food;
  const FoodItemCard({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BillProvider>();

    Set<String> roundParticipantIds = {};
    if (food.isRoundBased && food.roundNumber != null) {
      final round = prov.rounds.firstWhere(
            (r) => r.id == food.roundNumber,
        orElse: () => Round(id: '', name: '', participantIds: {}),
      );
      roundParticipantIds = round.participantIds;
    }

    final assignedNames = food.assigned.isEmpty
        ? (roundParticipantIds.isNotEmpty
        ? prov.people.where((p) => roundParticipantIds.contains(p.id)).map((p) => p.name).toList()
        : prov.people.map((p) => p.name).toList())
        : prov.people.where((p) => food.assigned.contains(p.id)).map((p) => p.name).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    food.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _openAssign(context, food),
                      icon: const Icon(Icons.group, size: 20),
                      tooltip: 'Assign',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _openEdit(context, food),
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: 'Edit',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₹${food.price.toStringAsFixed(2)} × ${food.qty} = ₹${(food.price * food.qty).toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (food.isRoundBased && food.roundNumber != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Round: ${prov.rounds.firstWhere((r) => r.id == food.roundNumber, orElse: () => Round(id: '', name: 'Unknown', participantIds: {})).name}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5)),
                ),
              )
            else
              Wrap(
                spacing: 6,
                children: assignedNames.map((n) => Chip(
                  label: Text(n, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.grey.shade100,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _openAssign(BuildContext context, FoodItem f) {
    final prov = context.read<BillProvider>();
    Set<String> selectableIds;
    String dialogTitle;

    if (f.isRoundBased && f.roundNumber != null) {
      final round = prov.rounds.firstWhere((r) => r.id == f.roundNumber, orElse: () => Round(id: '', name: '', participantIds: {}));
      selectableIds = round.participantIds;
      dialogTitle = 'Assign ${f.name} (${round.name})';
    } else {
      selectableIds = prov.people.map((p) => p.id).toSet();
      dialogTitle = 'Assign ${f.name}';
    }

    final selectablePeople = prov.people.where((p) => selectableIds.contains(p.id)).toList();
    if (selectablePeople.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No participants available')));
      return;
    }

    Set<String> localAssigned;
    if (f.isRoundBased && f.roundNumber != null && f.assigned.isEmpty) {
      localAssigned = Set.from(selectableIds);
    } else {
      localAssigned = Set.from(f.assigned.where((id) => selectableIds.contains(id)));
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text(dialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectablePeople.length > 1)
                  CheckboxListTile(
                    value: localAssigned.length == selectablePeople.length,
                    title: const Text('Select all'),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          localAssigned = selectableIds.toSet();
                        } else {
                          localAssigned.clear();
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                const Divider(),
                ...selectablePeople.map((p) => CheckboxListTile(
                  value: localAssigned.contains(p.id),
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
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                )),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  final result = localAssigned.isEmpty && selectablePeople.isNotEmpty ? selectableIds.toSet() : localAssigned;
                  prov.assignFood(f.id, result);
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openEdit(BuildContext context, FoodItem f) {
    final nameCtrl = TextEditingController(text: f.name);
    final priceCtrl = TextEditingController(text: f.price.toString());
    final qtyCtrl = TextEditingController(text: f.qty.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Edit Food'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: priceCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price')),
            const SizedBox(height: 12),
            TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.trim()) ?? f.price;
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? f.qty;
              context.read<BillProvider>().editFood(f.id, name: name, price: price, qty: qty);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}