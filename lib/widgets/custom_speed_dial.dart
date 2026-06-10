import 'package:flutter/material.dart';

class CustomSpeedDial extends StatelessWidget {
  final VoidCallback onAddFood;
  final VoidCallback? onAddPerson;
  final VoidCallback onOpenBillSplit;
  final VoidCallback onOpenBreakdown;
  final VoidCallback onScanBill;

  const CustomSpeedDial({
    super.key,
    required this.onAddFood,
    this.onAddPerson,
    required this.onOpenBillSplit,
    required this.onOpenBreakdown,
    required this.onScanBill,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.fastfood),
                  title: const Text('Add Food'),
                  onTap: () {
                    Navigator.pop(context);
                    onAddFood();
                  },
                ),
                if (onAddPerson != null)
                  ListTile(
                    leading: const Icon(Icons.person_add),
                    title: const Text('Add Person'),
                    onTap: () {
                      Navigator.pop(context);
                      onAddPerson!();
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.table_chart),
                  title: const Text('Full & Final'),
                  onTap: () {
                    Navigator.pop(context);
                    onOpenBillSplit();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('Breakdown'),
                  onTap: () {
                    Navigator.pop(context);
                    onOpenBreakdown();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.document_scanner),
                  title: const Text('Scan Bill'),
                  onTap: () {
                    Navigator.pop(context);
                    onScanBill();
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}