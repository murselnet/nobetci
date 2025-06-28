'''
import 'package:flutter/material.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final Size imageSize;
  final Size screenSize;

  BoundingBoxPainter({
    required this.detections,
    required this.imageSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    final double scaleX = screenSize.width / imageSize.width;
    final double scaleY = screenSize.height / imageSize.height;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    for (var detection in detections) {
      final rectData = detection['rect'];
      if (rectData == null) continue;

      // Modelden gelen normalize edilmiş koordinatları (0.0 - 1.0) al
      final double modelX = rectData['x'] ?? 0;
      final double modelY = rectData['y'] ?? 0;
      final double modelW = rectData['w'] ?? 0;
      final double modelH = rectData['h'] ?? 0;

      // Koordinatları ekran boyutuna göre ölçekle
      final Rect scaledRect = Rect.fromLTWH(
        modelX * imageSize.width * scaleX,
        modelY * imageSize.height * scaleY,
        modelW * imageSize.width * scaleX,
        modelH * imageSize.height * scaleY,
      );

      // Dikdörtgeni çiz
      canvas.drawRect(scaledRect, paint);

      // Etiket ve güven skorunu yaz
      final String label = detection['label'] ?? '';
      final double confidence = detection['confidence'] ?? 0;
      final String displayText = '$label ${(confidence * 100).toStringAsFixed(0)}%';

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: displayText,
          style: const TextStyle(
            color: Colors.white,
            backgroundColor: Colors.red,
            fontSize: 14.0,
          ),
        ),
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(scaledRect.left, scaledRect.top - textPainter.height));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Her zaman yeniden çizim yap
  }
}
'''