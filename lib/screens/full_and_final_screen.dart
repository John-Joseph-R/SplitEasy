import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../models/person.dart';

class FullAndFinalScreen extends StatefulWidget {
  @override
  _FullAndFinalScreenState createState() => _FullAndFinalScreenState();
}

class _FullAndFinalScreenState extends State<FullAndFinalScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BillProvider>(context, listen: false);
    for (var person in provider.people) {
      _controllers[person.id] = TextEditingController(
        text: provider.getPayment(person.id).toStringAsFixed(2),
      );
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) c.dispose();
    super.dispose();
  }

  void _savePayments() {
    final provider = Provider.of<BillProvider>(context, listen: false);
    for (var person in provider.people) {
      final amount = double.tryParse(_controllers[person.id]!.text) ?? 0.0;
      provider.setPayment(person.id, amount);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payments saved')),
    );
  }

  void _showSettlements() {
    final provider = Provider.of<BillProvider>(context, listen: false);
    final peopleList = provider.people;
    if (peopleList.isEmpty) return;

    final Map<String, double> balances = {};
    for (var p in peopleList) {
      double share = provider.getPersonShare(p.id);
      double paid = provider.getPayment(p.id);
      balances[p.id] = paid - share;
    }

    bool allSettled = balances.values.every((b) => b.abs() < 0.01);
    if (allSettled) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Final Settlements'),
          content: const Text('✅ All settled! Everyone paid exactly their share.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    final transfers = _calculateTransfers(balances, peopleList);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Final Settlements'),
        content: transfers.isEmpty
            ? const Text('⚠️ Unable to calculate settlements. Check payments and shares.')
            : Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: transfers.map((t) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('• ${t.fromName} pays ${t.toName} : ₹${t.amount.toStringAsFixed(2)}'),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (transfers.isNotEmpty) {
                final settlement = {
                  'timestamp': DateTime.now().toIso8601String(),
                  'transfers': transfers.map((t) => {
                    'from': t.fromName,
                    'to': t.toName,
                    'amount': t.amount,
                  }).toList(),
                };
                provider.addSettlementToHistory(settlement);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Transfer> _calculateTransfers(Map<String, double> balances, List<Person> people) {
    List<MapEntry<String, double>> debtors = [];
    List<MapEntry<String, double>> creditors = [];
    for (var entry in balances.entries) {
      if (entry.value < -0.01) debtors.add(MapEntry(entry.key, -entry.value));
      else if (entry.value > 0.01) creditors.add(MapEntry(entry.key, entry.value));
    }
    debtors.sort((a, b) => b.value.compareTo(a.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    List<Transfer> transfers = [];
    int i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      double settle = (debtors[i].value < creditors[j].value) ? debtors[i].value : creditors[j].value;
      transfers.add(Transfer(
        fromId: debtors[i].key,
        fromName: people.firstWhere((p) => p.id == debtors[i].key).name,
        toId: creditors[j].key,
        toName: people.firstWhere((p) => p.id == creditors[j].key).name,
        amount: settle,
      ));
      debtors[i] = MapEntry(debtors[i].key, debtors[i].value - settle);
      creditors[j] = MapEntry(creditors[j].key, creditors[j].value - settle);
      if (debtors[i].value <= 0.01) i++;
      if (creditors[j].value <= 0.01) j++;
    }
    return transfers;
  }

  void _showHistory() {
    final provider = Provider.of<BillProvider>(context, listen: false);
    final history = provider.settlementHistory;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settlement History'),
        content: history.isEmpty
            ? const Text('No past settlements.')
            : SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (_, i) {
              final entry = history[i];
              final date = DateTime.parse(entry['timestamp']);
              final transfers = entry['transfers'] as List;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text('${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}'),
                  subtitle: Text(transfers.map((t) => '${t['from']} → ${t['to']} ₹${t['amount']}').join(', ')),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BillProvider>(context);
    final peopleList = provider.people;

    if (peopleList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Full & Final'), actions: [
          IconButton(onPressed: _showHistory, icon: const Icon(Icons.history)),
        ]),
        body: const Center(child: Text('No participants added yet.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Full & Final Settlement'), actions: [
        IconButton(onPressed: _showHistory, icon: const Icon(Icons.history)),
      ]),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: peopleList.length,
              itemBuilder: (ctx, index) {
                final person = peopleList[index];
                final share = provider.getPersonShare(person.id);
                final paid = provider.getPayment(person.id);
                final balance = paid - share;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(person.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text('Share : ₹${share.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controllers[person.id],
                                decoration: const InputDecoration(
                                  labelText: 'Amount Paid (Cash / UPI)',
                                  border: OutlineInputBorder(),
                                  prefixText: '₹ ',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: _savePayments,
                              tooltip: 'Save payments',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Balance: ${balance >= 0 ? "🟢 Owed to them" : "🔴 They owe"} ₹${balance.abs().toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Net Balances', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...peopleList.map((p) {
                    double share = provider.getPersonShare(p.id);
                    double paid = provider.getPayment(p.id);
                    double balance = paid - share;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p.name),
                        Text(
                          balance >= 0 ? 'Gets ₹${balance.abs().toStringAsFixed(2)}' : 'Owes ₹${balance.abs().toStringAsFixed(2)}',
                          style: TextStyle(color: balance >= 0 ? Colors.green : Colors.red),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _showSettlements,
              icon: const Icon(Icons.calculate),
              label: const Text('Show Final Settlements'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ),
        ],
      ),
    );
  }
}

class Transfer {
  final String fromId, toId, fromName, toName;
  final double amount;
  Transfer({required this.fromId, required this.toName, required this.fromName, required this.toId, required this.amount});
}