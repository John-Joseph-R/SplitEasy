import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../screens/rounds_management_page.dart';

class AddFoodDialog extends StatefulWidget {
  final String? preSelectedRoundId;
  const AddFoodDialog({super.key, this.preSelectedRoundId});

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  String? selectedRoundId;

  @override
  void initState() {
    super.initState();
    selectedRoundId = widget.preSelectedRoundId;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BillProvider>();
    return AlertDialog(
      title: const Text('Add food'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: priceCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price')),
          TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
          const SizedBox(height: 12),
          if (prov.rounds.isEmpty && widget.preSelectedRoundId == null)
            Column(
              children: [
                const Text('No rounds created yet.'),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoundsManagementPage()),
                    );
                    showDialog(context: context, builder: (_) => const AddFoodDialog());
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create a round first'),
                ),
              ],
            )
          else if (prov.rounds.isNotEmpty && widget.preSelectedRoundId == null)
            DropdownButtonFormField<String>(
              value: selectedRoundId,
              decoration: const InputDecoration(labelText: 'Assign to Round (optional)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None (manual assignment)')),
                ...prov.rounds.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))),
              ],
              onChanged: (val) => setState(() => selectedRoundId = val),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final n = nameCtrl.text.trim();
            final p = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
            final q = int.tryParse(qtyCtrl.text.trim()) ?? 1;
            if (n.isEmpty || p <= 0 || q <= 0) return;
            context.read<BillProvider>().addFood(n, p, q, roundId: widget.preSelectedRoundId ?? selectedRoundId);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}