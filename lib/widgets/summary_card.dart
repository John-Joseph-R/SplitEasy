import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bill_provider.dart';

class SummaryCard extends StatelessWidget {
  final ScrollController? scrollController;
  SummaryCard({super.key, this.scrollController});
  final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BillProvider>();
    final totals = prov.perPersonTotals();
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
            if (prov.people.isEmpty) SizedBox(height: 40, child: Center(child: Text('No people added')))
            else SizedBox(height: 90, child: ListView.separated(itemCount: prov.people.length, itemBuilder: (_, i) { final p = prov.people[i]; final amt = totals[p.id] ?? 0.0; return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(p.name), Text(currency.format(amt), style: const TextStyle(fontWeight: FontWeight.w600))]); }, separatorBuilder: (_, __) => const SizedBox(height: 6))),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: FilledButton.icon(onPressed: () => _showBreakdown(context, prov), icon: const Icon(Icons.receipt_long), label: const Text('View'))), const SizedBox(width: 8), OutlinedButton.icon(onPressed: prov.people.isEmpty && prov.foods.isEmpty ? null : () => _exportCsv(context, prov), icon: const Icon(Icons.share), label: const Text('Export'))])
          ]),
        ),
      ),
    );
  }

  void _showBreakdown(BuildContext context, BillProvider prov) {
    final totals = prov.perPersonTotals();
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Breakdown'), content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Subtotal: ${currency.format(prov.subtotal)}'), const SizedBox(height: 8), prov.taxMode == TaxMode.percent ? Text('Taxes (percent): CGST ${prov.cgst}%, SGST ${prov.sgst}%, Service ${prov.service}%') : Text('Taxes (absolute): CGST ${currency.format(double.tryParse(prov.cgst) ?? 0)}, SGST ${currency.format(double.tryParse(prov.sgst) ?? 0)}, Service ${currency.format(double.tryParse(prov.service) ?? 0)}'), const SizedBox(height: 12), const Text('Per-person:'), const SizedBox(height: 8), ...prov.people.map((p) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${p.name}: ${currency.format(totals[p.id] ?? 0)}'))).toList(), const SizedBox(height: 12), const Text('Items:'), ...prov.foods.map((f) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${f.name}: ${currency.format(f.price)} × ${f.qty} = ${currency.format(f.price*f.qty)}'))).toList()])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
  }

  void _exportCsv(BuildContext context, BillProvider prov) {
    // build CSV and share using share_plus (you can implement a util). For modularity we keep provider focused on state and not sharing.
    final buffer = StringBuffer();
    buffer.writeln('Spliteasy export');
    buffer.writeln('Date,${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    buffer.writeln('Items:');
    buffer.writeln('Name,Price,Qty,Total,Assigned');
    for (var f in prov.foods) {
      final assignedNames = f.assigned.isEmpty ? (prov.people.isEmpty ? '—' : prov.people.map((p) => p.name).join('|')) : prov.people.where((p) => f.assigned.contains(p.id)).map((p) => p.name).join('|');
      buffer.writeln('"${f.name}",${f.price.toStringAsFixed(2)},${f.qty},${(f.price*f.qty).toStringAsFixed(2)},"$assignedNames"');
    }
    buffer.writeln('');
    buffer.writeln('Tax Mode,${prov.taxMode == TaxMode.percent ? 'Percent' : 'Absolute'}');
    if (prov.taxMode == TaxMode.percent) buffer.writeln('CGST%,SGST%,Service%'); else buffer.writeln('CGST_abs,SGST_abs,Service_abs');
    buffer.writeln('${prov.cgst},${prov.sgst},${prov.service}');
    buffer.writeln('');
    buffer.writeln('Per person totals:');
    buffer.writeln('Name,Amount');
    final totals = prov.perPersonTotals();
    for (var p in prov.people) buffer.writeln('"${p.name}",${totals[p.id]!.toStringAsFixed(2)}');
    buffer.writeln('');
    buffer.writeln('Grand Total,${totals.values.fold(0.0, (a,b)=>a+b).toStringAsFixed(2)}');

    // share
    // You will need to import share_plus at top-level if you want to call Share.share here.
    // For cleanness we simply show the CSV in a dialog for copy, or you can integrate share_plus in this method.
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('CSV'), content: SingleChildScrollView(child: Text(buffer.toString())), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
  }
}
