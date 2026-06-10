import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../models/food_item.dart';
import 'package:uuid/uuid.dart';

class BillScannerPage extends StatefulWidget {
  const BillScannerPage({super.key});

  @override
  State<BillScannerPage> createState() => _BillScannerPageState();
}

class _BillScannerPageState extends State<BillScannerPage> {
  String extractedText = "No text extracted yet.";
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: extractedText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    final text = await OcrService.extractText(picked.path);
    setState(() {
      extractedText = text ?? "No readable text found.";
      _controller.text = extractedText;
    });
  }

  List<FoodItem> _parseTextToFoodItems(String rawText) {
    final lines = rawText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final RegExp priceRegex = RegExp(r'(\d+(?:\.\d{1,2})?)\s*$');
    final List<FoodItem> items = [];

    for (var line in lines) {
      final match = priceRegex.firstMatch(line);
      double price = 0.0;
      String name = line;
      if (match != null) {
        price = double.tryParse(match.group(1)!) ?? 0.0;
        name = line.substring(0, match.start).trim();
      }
      if (name.isNotEmpty) {
        items.add(FoodItem(
          id: const Uuid().v4(),
          name: name,
          price: price,
          qty: 1,
        ));
      }
    }
    // If no items found, fallback to whole lines as names
    if (items.isEmpty) {
      for (var line in lines) {
        items.add(FoodItem(id: const Uuid().v4(), name: line, price: 0.0, qty: 1));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Bill")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Extracted text will appear here...",
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final foodItems = _parseTextToFoodItems(_controller.text);
                  Navigator.pop(context, foodItems);
                },
                icon: const Icon(Icons.check),
                label: const Text("Done"),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "camera_btn",
            onPressed: () => _pickImage(ImageSource.camera),
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "gallery_btn",
            onPressed: () => _pickImage(ImageSource.gallery),
            child: const Icon(Icons.photo),
          ),
        ],
      ),
    );
  }
}