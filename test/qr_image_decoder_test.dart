import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/data/config_transfer.dart';
import 'package:olivos_companion/features/qr/qr_image_decoder.dart';
import 'package:olivos_companion/features/qr/qr_png.dart';
import 'package:qr/qr.dart';

void main() {
  test('从图片中识别配置二维码', () async {
    final data = ConfigTransfer.encode([
      const InstanceConfigEntry(
        name: '测试实例',
        baseUrl: 'http://127.0.0.1:20480',
        autoLogin: true,
        password: 'password',
      ),
    ]);
    final qr = QrImage(
      QrCode(
        payload: QrPayload.fromString(data),
        errorCorrectLevel: QrErrorCorrectLevel.low,
      ),
    );

    final directory = await Directory.systemTemp.createTemp('olivos_qr_test_');
    final file = File('${directory.path}/qr.png');
    try {
      await file.writeAsBytes(encodeQrPng(qr));
      expect(await decodeQrCodeFromImage(file.path), data);
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
