import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:qr/qr.dart';

import 'qr_png.dart';

/// Saves the QR image to the gallery on mobile, or asks for a path on desktop.
///
/// Returns false when the user cancels the desktop save dialog.
Future<bool> saveQrImage(
  QrImage image, {
  String typeLabel = 'PNG image',
}) async {
  final bytes = encodeQrPng(image);
  final name = _fileName();

  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    await Gal.putImageBytes(bytes, name: name);
    return true;
  }

  final location = await getSaveLocation(
    suggestedName: '$name.png',
    acceptedTypeGroups: [
      XTypeGroup(
        label: typeLabel,
        extensions: ['png'],
        mimeTypes: ['image/png'],
      ),
    ],
  );
  if (location == null) return false;
  await File(location.path).writeAsBytes(bytes, flush: true);
  return true;
}

String _fileName() {
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  return 'olivos-companion-qr-${now.year}${two(now.month)}${two(now.day)}'
      '-${two(now.hour)}${two(now.minute)}${two(now.second)}';
}
