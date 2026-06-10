import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bill_provider.dart';
import '../models/person.dart';
import '../models/food_item.dart';

class SummaryCard extends StatelessWidget {
  final ScrollController? scrollController;
  final List<Person>? participants;
  final List<FoodItem>? foods;
  final TaxMode? taxMode;
  final String? cgst;
  final String? sgst;
  final String? service;

  SummaryCard({
    super.key,
    this.scrollController,
    this.participants,
    this.foods,
    this.taxMode,
    this.cgst,
    this.sgst,
    this.service,
  });

  final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BillProvider>();
    final effectiveParticipants = participants ?? prov.people;
    final effectiveFoods = foods ?? prov.foods;
    final effectiveTaxMode = taxMode ?? prov.taxMode;
    final effectiveCgst = cgst ?? prov.cgst;
    final effectiveSgst = sgst ?? prov.sgst;
    final effectiveService = service ?? prov.service;

    // Calculate totals manually (since we may have filtered lists)
    final subtotal = effectiveFoods.fold(0.0, (s, f) => s + f.price * f.qty);
    final Map<String, double> totals = {};
    for (var p in effectiveParticipants) totals[p.id] = 0.0;

    for (var f in effectiveFoods) {
      final cost = f.price * f.qty;
      final assigned = f.assigned.isNotEmpty ? f.assigned : effectiveParticipants.map((p) => p.id).toSet();
      if (assigned.isEmpty) continue;
      final share = cost / assigned.length;
      for (var pid in assigned) totals[pid] = (totals[pid] ?? 0) + share;
    }

    double _toDouble(String s) => double.tryParse(s) ?? 0.0;
    if (effectiveTaxMode == TaxMode.percent) {
      final multiplier = 1.0 + (_toDouble(effectiveCgst) + _toDouble(effectiveSgst) + _toDouble(effectiveService)) / 100.0;
      totals.updateAll((k, v) => v * multiplier);
    } else {
      final totalTax = _toDouble(effectiveCgst) + _toDouble(effectiveSgst) + _toDouble(effectiveService);
      final baseSum = totals.values.fold(0.0, (a, b) => a + b);
      if (baseSum <= 0.0001 && effectiveParticipants.isNotEmpty) {
        final equalShare = (subtotal + totalTax) / effectiveParticipants.length;
        for (var p in effectiveParticipants) totals[p.id] = equalShare;
      } else if (baseSum > 0) {
        totals.updateAll((k, v) {
          final taxShare = (v / baseSum) * totalTax;
          return v + taxShare;
        });
      }
    }

    final grand = totals.values.fold(0.0, (a, b) => a + b);

    return Container(
      color: Theme.of(context).colorScheme.background.withOpacity(0.98),
      padding: const EdgeInsets.all(12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [Expanded(child: Text('Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))), Text('Grand: ${currency.format(grand)}', style: const TextStyle(fontWeight: FontWeight.w700))]),
            const SizedBox(height: 8),
            if (effectiveParticipants.isEmpty)
              const SizedBox(height: 40, child: Center(child: Text('No participants')))
            else
              SizedBox(
                height: 90,
                child: ListView.separated(
                  itemCount: effectiveParticipants.length,
                  itemBuilder: (_, i) {
                    final p = effectiveParticipants[i];
                    final amt = totals[p.id] ?? 0.0;
                    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(p.name), Text(currency.format(amt), style: const TextStyle(fontWeight: FontWeight.w600))]);
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                ),
              ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showBreakdown(context, effectiveParticipants, effectiveFoods, subtotal, effectiveTaxMode, effectiveCgst, effectiveSgst, effectiveService, totals),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: effectiveParticipants.isEmpty && effectiveFoods.isEmpty ? null : () => _exportCsv(context, effectiveParticipants, effectiveFoods, effectiveTaxMode, effectiveCgst, effectiveSgst, effectiveService, totals),
                icon: const Icon(Icons.share),
                label: const Text('Export'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showBreakdown(BuildContext context, List<Person> people, List<FoodItem> foods, double subtotal, TaxMode taxMode, String cgst, String sgst, String service, Map<String, double> totals) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Breakdown'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Subtotal: ${currency.format(subtotal)}'),
              const SizedBox(height: 8),
              taxMode == TaxMode.percent
                  ? Text('Taxes (percent): CGST ${cgst}%, SGST ${sgst}%, Service ${service}%')
                  : Text('Taxes (absolute): CGST ${currency.format(double.tryParse(cgst) ?? 0)}, SGST ${currency.format(double.tryParse(sgst) ?? 0)}, Service ${currency.format(double.tryParse(service) ?? 0)}'),
              const SizedBox(height: 12),
              const Text('Per-person:'),
              const SizedBox(height: 8),
              ...people.map((p) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${p.name}: ${currency.format(totals[p.id] ?? 0)}'))).toList(),
              const SizedBox(height: 12),
              const Text('Items:'),
              ...foods.map((f) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${f.name}: ${currency.format(f.price)} × ${f.qty} = ${currency.format(f.price * f.qty)}'))).toList(),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _exportCsv(BuildContext context, List<Person> people, List<FoodItem> foods, TaxMode taxMode, String cgst, String sgst, String service, Map<String, double> totals) {
    final buffer = StringBuffer();
    buffer.writeln('Spliteasy export');
    buffer.writeln('Date,${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    buffer.writeln('Items:');
    buffer.writeln('Name,Price,Qty,Total,Assigned');
    for (var f in foods) {
      final assignedNames = f.assigned.isEmpty ? (people.isEmpty ? '—' : people.map((p) => p.name).join('|')) : people.where((p) => f.assigned.contains(p.id)).map((p) => p.name).join('|');
      buffer.writeln('"${f.name}",${f.price.toStringAsFixed(2)},${f.qty},${(f.price * f.qty).toStringAsFixed(2)},"$assignedNames"');
    }
    buffer.writeln('');
    buffer.writeln('Tax Mode,${taxMode == TaxMode.percent ? 'Percent' : 'Absolute'}');
    if (taxMode == TaxMode.percent) buffer.writeln('CGST%,SGST%,Service%');
    else buffer.writeln('CGST_abs,SGST_abs,Service_abs');
    buffer.writeln('$cgst,$sgst,$service');
    buffer.writeln('');
    buffer.writeln('Per person totals:');
    buffer.writeln('Name,Amount');
    for (var p in people) buffer.writeln('"${p.name}",${totals[p.id]?.toStringAsFixed(2) ?? "0.00"}');
    buffer.writeln('');
    buffer.writeln('Grand Total,${totals.values.fold(0.0, (a, b) => a + b).toStringAsFixed(2)}');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('CSV Export'),
        content: SingleChildScrollView(child: Text(buffer.toString())),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}