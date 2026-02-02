import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// CrÃ©e un marqueur directionnel avec halo et popup
class DirectionalMarker {
  /// CrÃ©e un BitmapDescriptor pour un marqueur directionnel
  ///
  /// [color] : Couleur du cercle principal
  /// [bearing] : Direction en degrÃ©s (0-360, 0 = Nord)
  /// [showPopup] : Afficher le popup avec icÃ´ne au-dessus
  /// [iconData] : IcÃ´ne Ã  afficher dans le popup (optionnel)
  static Future<void> createDirectionalMarker({
    required Color color,
    required double bearing,
    bool showPopup = true,
    IconData? iconData,
  }) async {
    const double markerSize = 80.0;
    const double circleRadius = 20.0;
    const double haloRadius = 40.0;
    const double popupRadius = 30.0;
    const double popupOffset = 45.0; // Distance du popup au-dessus du cercle

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(markerSize / 2, markerSize / 2);

    // 1. Dessiner le halo directionnel (ombre bleue qui s'Ã©tend dans la direction)

    // Calculer la position du halo dans la direction du bearing
    final bearingRad =
        (bearing - 90) *
        (3.14159 / 180); // Convertir en radians, ajuster pour 0Â° = Nord
    final haloOffsetX = center.dx + (haloRadius * 0.6 * -math.sin(bearingRad));
    final haloOffsetY = center.dy + (haloRadius * 0.6 * math.cos(bearingRad));

    // Dessiner un cercle avec gradient radial pour l'effet halo
    final haloGradient = RadialGradient(
      colors: [
        color.withOpacity(0.4),
        color.withOpacity(0.2),
        color.withOpacity(0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final haloGradientPaint = Paint()
      ..shader = haloGradient.createShader(
        Rect.fromCircle(
          center: Offset(haloOffsetX, haloOffsetY),
          radius: haloRadius,
        ),
      );

    canvas.drawCircle(
      Offset(haloOffsetX, haloOffsetY),
      haloRadius,
      haloGradientPaint,
    );

    // 2. Dessiner le cercle principal
    final circlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, circleRadius, circlePaint);
    canvas.drawCircle(center, circleRadius, borderPaint);

    // 3. Dessiner une petite flÃ¨che directionnelle sur le cercle
    final arrowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    final arrowPath = Path();
    final arrowLength = 8.0;
    final arrowX = center.dx + (circleRadius * 0.7 * -math.sin(bearingRad));
    final arrowY = center.dy + (circleRadius * 0.7 * math.cos(bearingRad));

    // Dessiner une petite flÃ¨che triangulaire
    arrowPath.moveTo(arrowX, arrowY);
    arrowPath.lineTo(
      arrowX + arrowLength * math.cos(bearingRad + 2.356),
      arrowY + arrowLength * math.sin(bearingRad + 2.356),
    );
    arrowPath.lineTo(
      arrowX + arrowLength * math.cos(bearingRad - 2.356),
      arrowY + arrowLength * math.sin(bearingRad - 2.356),
    );
    arrowPath.close();

    canvas.drawPath(arrowPath, arrowPaint);

    // 4. Dessiner le popup avec icÃ´ne au-dessus
    if (showPopup) {
      final popupCenter = Offset(center.dx, center.dy - popupOffset);

      // Cercle du popup avec ombre
      final popupShadowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.black.withOpacity(0.2);

      canvas.drawCircle(
        Offset(popupCenter.dx + 2, popupCenter.dy + 2),
        popupRadius,
        popupShadowPaint,
      );

      // Cercle du popup
      final popupPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white;

      final popupBorderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = 2.0;

      canvas.drawCircle(popupCenter, popupRadius, popupPaint);
      canvas.drawCircle(popupCenter, popupRadius, popupBorderPaint);

      // Dessiner l'icÃ´ne dans le popup
      if (iconData != null) {
        // Utiliser un TextPainter pour dessiner l'icÃ´ne
        final textStyle = TextStyle(
          fontFamily: iconData.fontFamily,
          fontSize: 20,
          color: color,
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(iconData.codePoint),
            style: textStyle,
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            popupCenter.dx - textPainter.width / 2,
            popupCenter.dy - textPainter.height / 2,
          ),
        );
      } else {
        // IcÃ´ne par dÃ©faut (livreur)
        final defaultIconPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = color;

        // Dessiner une icÃ´ne moto simple
        canvas.drawCircle(popupCenter, 6, defaultIconPaint);
        canvas.drawCircle(
          Offset(popupCenter.dx - 4, popupCenter.dy),
          3,
          defaultIconPaint,
        );
        canvas.drawCircle(
          Offset(popupCenter.dx + 4, popupCenter.dy),
          3,
          defaultIconPaint,
        );
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(markerSize.toInt(), markerSize.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    // return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// CrÃ©e un marqueur simple (cercle colorÃ© sans effet directionnel)
  static Future<void> createSimpleMarker({
    required Color color,
    double size = 40.0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - 4;

    // Cercle principal
    final circlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius, borderPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    // return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
}

