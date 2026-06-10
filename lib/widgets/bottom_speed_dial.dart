import 'package:flutter/material.dart';

class BottomSpeedDial extends StatefulWidget {
  final VoidCallback onAddFood;
  final VoidCallback? onAddPerson; // now nullable
  final VoidCallback onOpenBillSplit;
  final VoidCallback onOpenBreakdown;
  final VoidCallback onScanBill;

  const BottomSpeedDial({
    super.key,
    required this.onAddFood,
    this.onAddPerson,
    required this.onOpenBillSplit,
    required this.onOpenBreakdown,
    required this.onScanBill,
  });

  @override
  State<BottomSpeedDial> createState() => _BottomSpeedDialState();
}

class _BottomSpeedDialState extends State<BottomSpeedDial>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  }

  void toggleMenu() {
    setState(() => isExpanded = !isExpanded);
    isExpanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black.withOpacity(0.12))],
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 10,
            child: FloatingActionButton.small(
              heroTag: "bill_split",
              onPressed: widget.onOpenBillSplit,
              child: const Icon(Icons.table_chart),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 10,
            child: FloatingActionButton.small(
              heroTag: "breakdown",
              onPressed: widget.onOpenBreakdown,
              child: const Icon(Icons.receipt),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            bottom: isExpanded ? 80 : 20,
            child: IgnorePointer(
              ignoring: !isExpanded,
              child: ScaleTransition(
                scale: _animation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: "addFood",
                      label: const Text("Add Food"),
                      icon: const Icon(Icons.fastfood),
                      onPressed: () {
                        toggleMenu();
                        widget.onAddFood();
                      },
                    ),
                    if (widget.onAddPerson != null) ...[
                      const SizedBox(height: 12),
                      FloatingActionButton.extended(
                        heroTag: "addPerson",
                        label: const Text("Add Person"),
                        icon: const Icon(Icons.person_add),
                        onPressed: () {
                          toggleMenu();
                          widget.onAddPerson!();
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    FloatingActionButton.extended(
                      heroTag: "scanBill",
                      label: const Text("Scan Bill"),
                      icon: const Icon(Icons.document_scanner),
                      onPressed: () {
                        toggleMenu();
                        widget.onScanBill();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 5,
            child: GestureDetector(
              onTap: toggleMenu,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 65,
                width: 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple,
                  boxShadow: [BoxShadow(blurRadius: 14, color: Colors.deepPurple.withOpacity(0.4), spreadRadius: 2)],
                ),
                child: Icon(isExpanded ? Icons.close : Icons.add, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}