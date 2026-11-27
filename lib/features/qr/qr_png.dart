import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

/// Renders a QR matrix to a high-resolution PNG with a standard quiet zone.
Uint8List encodeQrPng(QrImage image) {
  const quietZone = 4;
  final modules = image.moduleCount + quietZone * 2;
  final scale = (1024 / modules).ceil().clamp(4, 16).toInt();
  final size = modules * scale;
  final output = img.Image(width: size, height: size, numChannels: 3);
  img.fill(output, color: img.ColorRgb8(255, 255, 255));

  for (var row = 0; row < image.moduleCount; row++) {
    for (var column = 0; column < image.moduleCount; column++) {
      if (!image.isDark(row, column)) continue;
      final left = (column + quietZone) * scale;
      final top = (row + quietZone) * scale;
      img.fillRect(
        output,
        x1: left,
        y1: top,
        x2: left + scale - 1,
        y2: top + scale - 1,
        color: img.ColorRgb8(0, 0, 0),
        alphaBlend: false,
      );
    }
  }

  return img.encodePng(output);
}
