import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';
import '../providers/bill_provider.dart';
import '../widgets/add_food_dialog.dart';
import '../widgets/add_person_dialog.dart';
import '../widgets/food_item_card.dart';
import '../widgets/person_chip.dart';
import '../widgets/summary_card.dart';
import '../screens/bill_scanner_page.dart';
import '../screens/rounds_management_page.dart';
import '../screens/full_and_final_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openBreakdownSheet(BuildContext context) {
    final prov = context.read<BillProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SummaryCard(
                scrollController: scrollController,
                participants: prov.people,
                foods: prov.foods,
                taxMode: prov.taxMode,
                cgst: prov.cgst,
                sgst: prov.sgst,
                service: prov.service,
              ),
            );
          },
        );
      },
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset everything?'),
        content: const Text('All people, food items, rounds, and payments will be erased.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context.read<BillProvider>().clearAll();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BillProvider>();
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Spliteasy'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoundsManagementPage())),
            icon: const Icon(Icons.group_work),
            tooltip: 'Rounds',
          ),
          IconButton(
            onPressed: prov.people.isEmpty && prov.foods.isEmpty ? null : () => _openBreakdownSheet(context),
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Summary',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FullAndFinalScreen()));
            },
            icon: const Icon(Icons.table_chart),
            tooltip: 'Full & Final',
          ),
          IconButton(
            onPressed: () async {
              final items = await Navigator.push(context, MaterialPageRoute(builder: (_) => const BillScannerPage()));
              if (items != null && items is List<FoodItem>) {
                for (var item in items) {
                  prov.addFood(item.name, item.price, item.qty);
                }
              }
            },
            icon: const Icon(Icons.scanner),
            tooltip: 'Scan Bill',
          ),
          IconButton(
            onPressed: () => _confirmReset(context),
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // People section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('People', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  if (prov.people.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => showDialog(context: context, builder: (_) => const AddPersonDialog()),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Add'),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              prov.people.isEmpty
                  ? _buildEmptyState('No people yet', Icons.person_off, () => showDialog(context: context, builder: (_) => const AddPersonDialog()))
                  : Wrap(
                spacing: 10,
                runSpacing: 10,
                children: prov.people.map((p) => PersonChip(person: p)).toList(),
              ),
              const SizedBox(height: 24),

              // Food items section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Food Items', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  FilledButton.icon(
                    onPressed: () => showDialog(context: context, builder: (_) => const AddFoodDialog()),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Food'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 3,
                child: prov.foods.isEmpty
                    ? _buildEmptyState('No food items', Icons.fastfood, () => showDialog(context: context, builder: (_) => const AddFoodDialog()))
                    : ListView.separated(
                  itemCount: prov.foods.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => FoodItemCard(food: prov.foods[i]),
                ),
              ),

              const SizedBox(height: 16),

              // Taxes & Service card
              Text('Taxes & Service', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _TaxesTile(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(text, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

// ==================== Taxes Tile Widget ====================
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
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final subtotal = prov.subtotal;
    final totals = prov.perPersonTotals();
    final total = totals.values.fold(0.0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Mode:'),
            DropdownButton<TaxMode>(
              value: _mode,
              items: const [
                DropdownMenuItem(value: TaxMode.percent, child: Text('Percent %')),
                DropdownMenuItem(value: TaxMode.absolute, child: Text('Absolute ₹')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _mode = v);
                prov.updateTaxes(mode: v);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cgst,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _mode == TaxMode.percent ? 'CGST %' : 'CGST ₹',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _sgst,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _mode == TaxMode.percent ? 'SGST %' : 'SGST ₹',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _service,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _mode == TaxMode.percent ? 'Service %' : 'Service ₹',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                prov.updateTaxes(mode: _mode, cgstV: _cgst.text, sgstV: _sgst.text, serviceV: _service.text);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Taxes updated')));
              },
              icon: const Icon(Icons.update),
              label: const Text('Apply'),
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtotal: ${currency.format(subtotal)}'),
            Text('Total: ${currency.format(total)}', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}