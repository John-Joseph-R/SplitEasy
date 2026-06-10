import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';
import '../models/round.dart';
import '../providers/bill_provider.dart';
import '../widgets/add_food_dialog.dart';
import '../widgets/add_person_dialog.dart';
import '../widgets/food_item_card.dart';
import '../widgets/person_chip.dart';
import '../widgets/summary_card.dart';
import '../widgets/bottom_speed_dial.dart';
import '../screens/bill_scanner_page.dart';
import '../screens/rounds_management_page.dart';
import '../screens/full_and_final_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openBreakdownSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          maxChildSize: 0.85,
          minChildSize: 0.32,
          builder: (context, scrollController) {
            return SummaryCard(scrollController: scrollController);
          },
        );
      },
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset data?'),
        content: const Text('This will clear saved people, foods, rounds, and payments.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context.read<BillProvider>().clearAll();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // ✅ THIS IS THE FIXED DIALOG METHOD – IT MUST BE DEFINED INSIDE THE STATELESS WIDGET
  void _showCreateRoundDialog(BuildContext context) {
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
      barrierDismissible: true,
      builder: (dialogContext) {
        // We use StatefulBuilder to manage the checkbox state inside the dialog
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Create New Round'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Round Name',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Participants:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
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
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Round "$roundName" created!')),
                    );
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BillProvider>();
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spliteasy'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoundsManagementPage()),
              );
            },
            icon: const Icon(Icons.group_work),
            tooltip: 'Manage Rounds',
          ),
          IconButton(
            onPressed: prov.people.isEmpty && prov.foods.isEmpty ? null : () => _openBreakdownSheet(context),
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Summary',
          ),
          IconButton(
            onPressed: () => _confirmReset(context),
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // People section
                Text('People', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                prov.people.isEmpty
                    ? InkWell(
                  onTap: () => showDialog(context: context, builder: (_) => const AddPersonDialog()),
                  child: Card(
                    elevation: 2,
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.person_add, size: 20), SizedBox(width: 8), Text('No people yet. Tap to add.')]),
                    ),
                  ),
                )
                    : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...prov.people.map((p) => PersonChip(person: p)),
                    // Add Person button
                    InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () => showDialog(context: context, builder: (_) => const AddPersonDialog()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(30)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 20, color: Colors.blue), SizedBox(width: 4), Text("Add", style: TextStyle(color: Colors.blue))]),
                      ),
                    ),
                    // Create Round chip – NOW CALLS THE DIALOG METHOD
                    if (prov.people.isNotEmpty)
                      InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () => _showCreateRoundDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.15), borderRadius: BorderRadius.circular(30)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.group_work, size: 20, color: Colors.deepPurple), SizedBox(width: 4), Text("Create Round", style: TextStyle(color: Colors.deepPurple))]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Food items section
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Food Items', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 8),
                prov.foods.isEmpty
                    ? InkWell(
                  onTap: () => showDialog(context: context, builder: (_) => const AddFoodDialog()),
                  child: Card(
                    elevation: 2,
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.fastfood, size: 20), SizedBox(width: 8), Text('No items yet. Tap to add.')]),
                    ),
                  ),
                )
                    : Column(children: prov.foods.map((f) => FoodItemCard(food: f)).toList()),
                const SizedBox(height: 20),

                // Taxes section
                Text('Taxes & Service', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: _TaxesTile())),
                const SizedBox(height: 20),

                // Assignments preview
                Text('Assignments', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Column(
                  children: prov.foods.map((f) => ListTile(
                    title: Text('${f.name} (${f.qty})'),
                    subtitle: Text(f.isRoundBased && f.roundNumber != null
                        ? 'Round: ${prov.rounds.firstWhere((r) => r.id == f.roundNumber, orElse: () => Round(id: '', name: 'Unknown', participantIds: {})).name}'
                        : 'Assigned: ${f.assigned.isEmpty ? prov.people.map((p) => p.name).join(', ') : prov.people.where((p) => f.assigned.contains(p.id)).map((p) => p.name).join(', ')}'),
                    trailing: Text(currency.format(f.price * f.qty)),
                  )).toList(),
                ),
                const SizedBox(height: 140),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomSpeedDial(
        onAddFood: () => showDialog(context: context, builder: (_) => const AddFoodDialog()),
        onAddPerson: () => showDialog(context: context, builder: (_) => const AddPersonDialog()),
        onOpenBillSplit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullAndFinalScreen())),
        onOpenBreakdown: () => _openBreakdownSheet(context),
        onScanBill: () async {
          final items = await Navigator.push(context, MaterialPageRoute(builder: (_) => const BillScannerPage()));
          if (items != null && items is List<FoodItem>) {
            for (var item in items) {
              context.read<BillProvider>().addFood(item.name, item.price, item.qty);
            }
          }
        },
      ),
    );
  }
}

// ============================ Taxes Tile Widget (unchanged) ============================
class _TaxesTile extends StatefulWidget {
  @override
  State<_TaxesTile> createState() => _TaxesTileState();
}

class _TaxesTileState extends State<_TaxesTile> {
  late TaxMode _mode;
  late TextEditingController _cgst;
  late TextEditingController _sgst;
  late TextEditingController _service;

  @override
  void initState() {
    super.initState();
    _cgst = TextEditingController();
    _sgst = TextEditingController();
    _service = TextEditingController();
    _mode = TaxMode.percent;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final prov = context.read<BillProvider>();
    _mode = prov.taxMode;
    _cgst.text = prov.cgst;
    _sgst.text = prov.sgst;
    _service.text = prov.service;
  }

  @override
  void dispose() {
    _cgst.dispose();
    _sgst.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<BillProvider>();
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Mode:'),
          DropdownButton<TaxMode>(
            value: _mode,
            items: const [DropdownMenuItem(value: TaxMode.percent, child: Text('Percent %')), DropdownMenuItem(value: TaxMode.absolute, child: Text('Absolute ₹'))],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _mode = v);
              prov.updateTaxes(mode: v);
            },
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: _cgst, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: _mode == TaxMode.percent ? 'CGST %' : 'CGST ₹'))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _sgst, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: _mode == TaxMode.percent ? 'SGST %' : 'SGST ₹'))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _service, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: _mode == TaxMode.percent ? 'Service %' : 'Service ₹'))),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              prov.updateTaxes(mode: _mode, cgstV: _cgst.text, sgstV: _sgst.text, serviceV: _service.text);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Taxes updated')));
            },
            icon: const Icon(Icons.update),
            label: const Text('Apply'),
          ),
        ]),
        const SizedBox(height: 12),
        Builder(builder: (ctx) {
          final subtotal = prov.subtotal;
          final totals = prov.perPersonTotals();
          final total = totals.values.fold(0.0, (a, b) => a + b);
          final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
          return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Subtotal: ${currency.format(subtotal)}'),
            Text('Total: ${currency.format(total)}', style: const TextStyle(fontWeight: FontWeight.w600)),
          ]);
        }),
      ],
    );
  }
}