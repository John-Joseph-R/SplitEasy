import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/bill_provider.dart';
import '../models/person.dart';
import '../models/food_item.dart';

class SummaryCard extends StatelessWidget {
  final ScrollController? scrollController;
  final List<Person> participants;
  final List<FoodItem> foods;
  final TaxMode taxMode;
  final String cgst;
  final String sgst;
  final String service;

  const SummaryCard({
    super.key,
    this.scrollController,
    required this.participants,
    required this.foods,
    required this.taxMode,
    required this.cgst,
    required this.sgst,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    final subtotal = foods.fold(0.0, (s, f) => s + f.price * f.qty);
    final Map<String, double> totals = {};
    for (var p in participants) totals[p.id] = 0.0;

    for (var f in foods) {
      final cost = f.price * f.qty;
      final assigned = f.assigned.isNotEmpty ? f.assigned : participants.map((p) => p.id).toSet();
      if (assigned.isEmpty) continue;
      final share = cost / assigned.length;
      for (var pid in assigned) totals[pid] = (totals[pid] ?? 0) + share;
    }

    double _toDouble(String s) => double.tryParse(s) ?? 0.0;
    if (taxMode == TaxMode.percent) {
      final multiplier = 1.0 + (_toDouble(cgst) + _toDouble(sgst) + _toDouble(service)) / 100.0;
      totals.updateAll((k, v) => v * multiplier);
    } else {
      final totalTax = _toDouble(cgst) + _toDouble(sgst) + _toDouble(service);
      final baseSum = totals.values.fold(0.0, (a, b) => a + b);
      if (baseSum <= 0.0001 && participants.isNotEmpty) {
        final equalShare = (subtotal + totalTax) / participants.length;
        for (var p in participants) totals[p.id] = equalShare;
      } else if (baseSum > 0) {
        totals.updateAll((k, v) {
          final taxShare = (v / baseSum) * totalTax;
          return v + taxShare;
        });
      }
    }

    final grand = totals.values.fold(0.0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Grand: ${currency.format(grand)}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (participants.isEmpty)
            const Center(child: Text('No participants'))
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                controller: scrollController,
                itemCount: participants.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final p = participants[i];
                  final amt = totals[p.id] ?? 0.0;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(currency.format(amt), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showBreakdownDialog(context, subtotal, totals, currency),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _exportCsv(context, subtotal, totals, currency),
                  icon: const Icon(Icons.share),
                  label: const Text('Export'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBreakdownDialog(BuildContext context, double subtotal, Map<String, double> totals, NumberFormat currency) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Breakdown'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Subtotal: ${currency.format(subtotal)}'),
              const SizedBox(height: 8),
              Text(taxMode == TaxMode.percent
                  ? 'Taxes: CGST ${cgst}%, SGST ${sgst}%, Service ${service}%'
                  : 'Taxes: CGST ${currency.format(double.tryParse(cgst) ?? 0)}, SGST ${currency.format(double.tryParse(sgst) ?? 0)}, Service ${currency.format(double.tryParse(service) ?? 0)}'),
              const SizedBox(height: 12),
              const Text('Per person:', style: TextStyle(fontWeight: FontWeight.w600)),
              ...participants.map((p) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(p.name), Text(currency.format(totals[p.id] ?? 0))]),
              )),
              const SizedBox(height: 12),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.w600)),
              ...foods.map((f) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${f.name}: ${currency.format(f.price)} × ${f.qty} = ${currency.format(f.price * f.qty)}'),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _exportCsv(BuildContext context, double subtotal, Map<String, double> totals, NumberFormat currency) {
    final buffer = StringBuffer();
    buffer.writeln('Spliteasy Export');
    buffer.writeln('Date,${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    buffer.writeln('Items:');
    buffer.writeln('Name,Price,Qty,Total,Assigned');
    for (var f in foods) {
      final assignedNames = f.assigned.isEmpty
          ? (participants.isEmpty ? '—' : participants.map((p) => p.name).join('|'))
          : participants.where((p) => f.assigned.contains(p.id)).map((p) => p.name).join('|');
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
    for (var p in participants) buffer.writeln('"${p.name}",${totals[p.id]?.toStringAsFixed(2) ?? "0.00"}');
    buffer.writeln('');
    buffer.writeln('Grand Total,${totals.values.fold(0.0, (a, b) => a + b).toStringAsFixed(2)}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Export CSV'),
        content: SingleChildScrollView(child: Text(buffer.toString())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}