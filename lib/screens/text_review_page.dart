import 'package:flutter/material.dart';

class TextReviewPage extends StatefulWidget {
  final String extractedText;

  const TextReviewPage({super.key, required this.extractedText});

  @override
  State<TextReviewPage> createState() => _TextReviewPageState();
}

class _TextReviewPageState extends State<TextReviewPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.extractedText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Review & Edit")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _controller,
          maxLines: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Edit recognized text",
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, _controller.text.trim());
        },
        label: const Text("Done"),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
