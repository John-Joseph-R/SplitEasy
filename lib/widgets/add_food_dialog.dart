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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Add food item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name'), autofocus: true),
          const SizedBox(height: 16),
          TextField(controller: priceCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price (₹)')),
          const SizedBox(height: 16),
          TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
          const SizedBox(height: 16),
          if (prov.rounds.isEmpty && widget.preSelectedRoundId == null)
            Column(
              children: [
                const Text('No rounds yet – create one first'),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const RoundsManagementPage()));
                    if (context.mounted) showDialog(context: context, builder: (_) => const AddFoodDialog());
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create round'),
                ),
              ],
            )
          else if (prov.rounds.isNotEmpty && widget.preSelectedRoundId == null)
            DropdownButtonFormField<String>(
              value: selectedRoundId,
              decoration: const InputDecoration(labelText: 'Round (optional)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None (manual split)')),
                ...prov.rounds.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))),
              ],
              onChanged: (v) => setState(() => selectedRoundId = v),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final name = nameCtrl.text.trim();
            final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
            final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
            if (name.isEmpty || price <= 0 || qty <= 0) return;
            prov.addFood(name, price, qty, roundId: widget.preSelectedRoundId ?? selectedRoundId);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}