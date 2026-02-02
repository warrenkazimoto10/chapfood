import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class MapboxDirectionalMarker {
  static Future<Uint8List> createSimpleMarkerImage({
    required Color color,
    required double size,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double radius = size / 2;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw circle
    canvas.drawCircle(Offset(radius, radius), radius - 2, paint);
    canvas.drawCircle(Offset(radius, radius), radius - 2, borderPaint);

    final ui.Image image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  static Future<Uint8List> createDirectionalMarkerImage({
    required Color color,
    required double size,
    required double bearing,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double radius = size / 2;

    // Rotate canvas around center
    canvas.translate(radius, radius);
    canvas.rotate(bearing * (3.14159 / 180)); // Convert degrees to radians
    canvas.translate(-radius, -radius);

    final Path path = Path();
    path.moveTo(radius, 0); // Top point
    path.lineTo(size, size); // Bottom right
    path.lineTo(radius, size * 0.7); // Bottom center indentation
    path.lineTo(0, size); // Bottom left
    path.close();

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    final ui.Image image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}
