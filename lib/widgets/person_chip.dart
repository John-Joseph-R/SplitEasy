import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/bill_provider.dart';

class PersonChip extends StatelessWidget {
  final Person person;
  final bool deletable;
  const PersonChip({super.key, required this.person, this.deletable = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, size: 16, color: Color(0xFF4F46E5)),
            const SizedBox(width: 6),
            Text(person.name, style: const TextStyle(fontWeight: FontWeight.w500)),
            if (deletable) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => context.read<BillProvider>().removePerson(person.id),
                child: const Icon(Icons.close, size: 16, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}