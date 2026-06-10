import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';
import '../models/person.dart';
import '../models/round.dart';
import '../providers/bill_provider.dart';
import '../widgets/add_food_dialog.dart';
import '../widgets/food_item_card.dart';
import '../widgets/person_chip.dart';
import '../widgets/summary_card.dart';
import '../screens/bill_scanner_page.dart';
import '../screens/full_and_final_screen.dart';

class RoundDetailScreen extends StatelessWidget {
  final Round round;
  const RoundDetailScreen({super.key, required this.round});

  void _openBreakdownSheet(BuildContext context, List<Person> participants, List<FoodItem> roundFoods) {
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
                participants: participants,
                foods: roundFoods,
                taxMode: context.read<BillProvider>().taxMode,
                cgst: context.read<BillProvider>().cgst,
                sgst: context.read<BillProvider>().sgst,
                service: context.read<BillProvider>().service,
              ),
            );
          },
        );
      },
    );
  }

  void _showAddFoodDialog(BuildContext context, String roundId) {
    showDialog(
      context: context,
      builder: (_) => AddFoodDialog(preSelectedRoundId: roundId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BillProvider>();
    final participants = prov.people.where((p) => round.participantIds.contains(p.id)).toList();
    final roundFoods = prov.foods.where((f) => f.roundNumber == round.id).toList();
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(round.name),
        actions: [
          IconButton(
            onPressed: () async {
              final items = await Navigator.push(context, MaterialPageRoute(builder: (_) => const BillScannerPage()));
              if (items != null && items is List<FoodItem>) {
                for (var item in items) {
                  prov.addFood(item.name, item.price, item.qty, roundId: round.id);
                }
              }
            },
            icon: const Icon(Icons.scanner),
          ),
          IconButton(
            onPressed: roundFoods.isEmpty ? null : () => _openBreakdownSheet(context, participants, roundFoods),
            icon: const Icon(Icons.bar_chart),
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullAndFinalScreen(roundId: round.id))),
            icon: const Icon(Icons.table_chart),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Participants
            Text('Participants', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: participants.map((p) => PersonChip(person: p, deletable: false)).toList(),
            ),
            const SizedBox(height: 24),

            // Food items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Food Items', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                FilledButton.icon(
                  onPressed: () => _showAddFoodDialog(context, round.id),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Food'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: roundFoods.isEmpty
                  ? _buildEmptyState('No items in this round', Icons.fastfood, () => _showAddFoodDialog(context, round.id))
                  : ListView.separated(
                itemCount: roundFoods.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) => FoodItemCard(food: roundFoods[i]),
              ),
            ),
          ],
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