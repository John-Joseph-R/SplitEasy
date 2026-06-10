import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';
import '../models/round.dart';
import '../providers/bill_provider.dart';
import '../widgets/add_food_dialog.dart';
import '../widgets/food_item_card.dart';
import '../widgets/person_chip.dart';
import '../widgets/summary_card.dart';
import '../widgets/bottom_speed_dial.dart';
import '../screens/bill_scanner_page.dart';
import '../screens/full_and_final_screen.dart';
import '../models/person.dart';

class RoundDetailScreen extends StatelessWidget {
  final Round round;
  const RoundDetailScreen({super.key, required this.round});

  void _openBreakdownSheet(BuildContext context, List<Person> participants, List<FoodItem> roundFoods) {
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
            return SummaryCard(
              scrollController: scrollController,
              participants: participants,
              foods: roundFoods,
              taxMode: context.read<BillProvider>().taxMode,
              cgst: context.read<BillProvider>().cgst,
              sgst: context.read<BillProvider>().sgst,
              service: context.read<BillProvider>().service,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BillProvider>();
    final participants = prov.people.where((p) => round.participantIds.contains(p.id)).toList();
    final roundFoods = prov.foods.where((f) => f.roundNumber == round.id).toList();
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text('Round: ${round.name}'),
        actions: [
          IconButton(
            onPressed: roundFoods.isEmpty ? null : () => _openBreakdownSheet(context, participants, roundFoods),
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Summary',
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
                // Participants
                Text('Participants', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: participants.map((p) => PersonChip(person: p, deletable: false)).toList(),
                ),
                const SizedBox(height: 20),

                // Food Items for this round
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Food Items', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 8),
                roundFoods.isEmpty
                    ? InkWell(
                  onTap: () => _showAddFoodDialog(context, round.id),
                  child: Card(
                    elevation: 2,
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.fastfood, size: 20), SizedBox(width: 8), Text('No items yet. Tap to add.')]),
                    ),
                  ),
                )
                    : Column(children: roundFoods.map((f) => FoodItemCard(food: f)).toList()),
                const SizedBox(height: 20),

                // Taxes & Service
                Text('Taxes & Service', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: _RoundTaxesTile())),
                const SizedBox(height: 20),

                // Assignments preview
                Text('Assignments', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Column(
                  children: roundFoods.map((f) => ListTile(
                    title: Text('${f.name} (${f.qty})'),
                    subtitle: Text('Split among: ${participants.map((p) => p.name).join(', ')}'),
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
        onAddFood: () => _showAddFoodDialog(context, round.id),
        onAddPerson: null, // No adding people from round screen
        onOpenBillSplit: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FullAndFinalScreen(roundId: round.id)),
          );
        },
        onOpenBreakdown: () => _openBreakdownSheet(context, participants, roundFoods),
        onScanBill: () async {
          final items = await Navigator.push(context, MaterialPageRoute(builder: (_) => const BillScannerPage()));
          if (items != null && items is List<FoodItem>) {
            for (var item in items) {
              context.read<BillProvider>().addFood(item.name, item.price, item.qty, roundId: round.id);
            }
          }
        },
      ),
    );
  }

  void _showAddFoodDialog(BuildContext context, String roundId) {
    showDialog(
      context: context,
      builder: (_) => AddFoodDialog(preSelectedRoundId: roundId),
    );
  }
}

// Reusable taxes widget (same as in home_screen but simplified)
class _RoundTaxesTile extends StatefulWidget {
  @override
  State<_RoundTaxesTile> createState() => _RoundTaxesTileState();
}

class _RoundTaxesTileState extends State<_RoundTaxesTile> {
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