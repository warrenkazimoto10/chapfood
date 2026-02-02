import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Crée des marqueurs directionnels pour Mapbox
/// Génère des images PNG qui peuvent être utilisées comme icônes de marqueurs
class MapboxDirectionalMarker {
  /// Crée une image pour un marqueur directionnel
  ///
  /// [color] : Couleur du cercle principal
  /// [bearing] : Direction en degrés (0-360, 0 = Nord)
  /// [showPopup] : Afficher le popup avec icône au-dessus
  /// [iconData] : Icône à afficher dans le popup (optionnel)
  /// 
  /// Retourne les bytes de l'image PNG
  static Future<Uint8List> createDirectionalMarkerImage({
    required Color color,
    required double bearing,
    bool showPopup = true,
    IconData? iconData,
  }) async {
    const double markerSize = 80.0;
    const double circleRadius = 20.0;
    const double haloRadius = 40.0;
    const double popupRadius = 30.0;
    const double popupOffset = 45.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(markerSize / 2, markerSize / 2);

    // 1. Dessiner le halo directionnel
    final bearingRad = (bearing - 90) * (3.14159 / 180);
    final haloOffsetX = center.dx + (haloRadius * 0.6 * -math.sin(bearingRad));
    final haloOffsetY = center.dy + (haloRadius * 0.6 * math.cos(bearingRad));

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

    // 3. Dessiner la flèche directionnelle
    final arrowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    final arrowPath = Path();
    final arrowLength = 8.0;
    final arrowX = center.dx + (circleRadius * 0.7 * -math.sin(bearingRad));
    final arrowY = center.dy + (circleRadius * 0.7 * math.cos(bearingRad));

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

    // 4. Dessiner le popup si demandé
    if (showPopup) {
      final popupCenter = Offset(center.dx, center.dy - popupOffset);

      // Ombre du popup
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

      // Dessiner l'icône
      if (iconData != null) {
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
        // Icône par défaut (livreur)
        final defaultIconPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = color;

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

    return byteData!.buffer.asUint8List();
  }

  /// Crée une image pour un marqueur simple (cercle coloré)
  static Future<Uint8List> createSimpleMarkerImage({
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

    return byteData!.buffer.asUint8List();
  }

  /// Génère un ID unique pour une image de marqueur basé sur ses propriétés
  static String generateMarkerId({
    required Color color,
    required double bearing,
    bool showPopup = true,
  }) {
    final colorHex = color.value.toRadixString(16).padLeft(8, '0');
    final bearingInt = bearing.round();
    final popupStr = showPopup ? 'popup' : 'nopopup';
    return 'marker_${colorHex}_${bearingInt}_$popupStr';
  }
}
