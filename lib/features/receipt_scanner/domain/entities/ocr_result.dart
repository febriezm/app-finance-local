/// Model hasil pembacaan OCR on-device.
class OcrLine {
  final String text;
  final int lineNumber;
  final double? confidence;

  const OcrLine({
    required this.text,
    required this.lineNumber,
    this.confidence,
  });
}

class OcrResult {
  final String rawText;
  final List<OcrLine> lines;
  final String? imagePath;

  const OcrResult({
    required this.rawText,
    required this.lines,
    this.imagePath,
  });

  factory OcrResult.fromString(String text, {String? imagePath}) {
    final rawLines = text.split('\n');
    final lines = <OcrLine>[];
    for (int i = 0; i < rawLines.length; i++) {
      final lineText = rawLines[i].trim();
      if (lineText.isNotEmpty) {
        lines.add(OcrLine(text: lineText, lineNumber: i + 1));
      }
    }
    return OcrResult(
      rawText: text,
      lines: lines,
      imagePath: imagePath,
    );
  }

  bool get isEmpty => rawText.trim().isEmpty;
}
