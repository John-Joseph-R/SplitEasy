import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class OcrService {
  static Future<String?> extractText(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final textRecognizer = TextRecognizer();

    final recognisedText = await textRecognizer.processImage(inputImage);

    await textRecognizer.close();

    return recognisedText.text;
  }
}
