import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:olivos_companion/data/config_transfer.dart';
import 'package:olivos_companion/features/qr/qr_image_decoder.dart';
import 'package:olivos_companion/features/qr/qr_png.dart';
import 'package:path/path.dart' as p;
import 'package:qr/qr.dart';

import 'support/test_fixtures.dart';

QrImage _qrFor(String data) {
  return QrImage(
    QrCode(
      payload: QrPayload.fromString(data),
      errorCorrectLevel: QrErrorCorrectLevel.low,
    ),
  );
}

void main() {
  final data = ConfigTransfer.encode([
    const InstanceConfigEntry(
      name: '测试实例',
      baseUrl: testBaseUrl,
      autoLogin: true,
      password: testPassword,
    ),
  ]);

  test('从图片中识别配置二维码', () async {
    final directory = await Directory.systemTemp.createTemp('olivos_qr_test_');
    final file = File(p.join(directory.path, 'qr.png'));
    try {
      await file.writeAsBytes(encodeQrPng(_qrFor(data)));
      expect(await decodeQrCodeFromImage(file.path), data);
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('反色二维码也能识别', () async {
    final normal = img.decodePng(encodeQrPng(_qrFor(data)))!;
    final inverted = img.invert(normal);
    final directory = await Directory.systemTemp.createTemp('olivos_qr_test_');
    final file = File(p.join(directory.path, 'qr-inverted.png'));
    try {
      await file.writeAsBytes(img.encodePng(inverted));
      expect(await decodeQrCodeFromImage(file.path), data);
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('没有二维码的图片返回 null', () async {
    final blank = img.Image(width: 200, height: 200);
    img.fill(blank, color: img.ColorRgb8(255, 255, 255));
    final directory = await Directory.systemTemp.createTemp('olivos_qr_test_');
    final file = File(p.join(directory.path, 'blank.png'));
    try {
      await file.writeAsBytes(img.encodePng(blank));
      expect(await decodeQrCodeFromImage(file.path), isNull);
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('无效图片返回 null', () async {
    final directory = await Directory.systemTemp.createTemp('olivos_qr_test_');
    final file = File(p.join(directory.path, 'invalid.png'));
    try {
      await file.writeAsString('not an image');
      expect(await decodeQrCodeFromImage(file.path), isNull);
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
