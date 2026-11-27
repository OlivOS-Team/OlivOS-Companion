import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

/// Decodes a QR code from an image file selected by the user.
///
/// This is pure Dart so it works on mobile and desktop, including Windows.
Future<String?> decodeQrCodeFromImage(String path) async {
  final bytes = await File(path).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  final image = img.bakeOrientation(decoded);
  final pixels = image
      .convert(numChannels: 4)
      .getBytes(order: img.ChannelOrder.rgba)
      .buffer
      .asInt32List();
  final source = RGBLuminanceSource(image.width, image.height, pixels);
  final hints = DecodeHints()..put(DecodeHintType.tryHarder);

  try {
    return QRCodeReader()
        .decode(BinaryBitmap(HybridBinarizer(source)), hints: hints)
        .text;
  } on ReaderException {
    // Try inverted QR codes as a fallback.
  }

  try {
    return QRCodeReader()
        .decode(
          BinaryBitmap(HybridBinarizer(InvertedLuminanceSource(source))),
          hints: hints,
        )
        .text;
  } on ReaderException {
    return null;
  }
}
