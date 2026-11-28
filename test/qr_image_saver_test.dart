import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/data/config_transfer.dart';
import 'package:olivos_companion/features/qr/qr_image_decoder.dart';
import 'package:olivos_companion/features/qr/qr_image_saver.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();
  late TargetPlatform? originalTargetPlatform;
  final channel = const MethodChannel('plugins.flutter.io/file_selector');
  final galChannel = const MethodChannel('gal');

  setUp(() {
    originalTargetPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = originalTargetPlatform;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(galChannel, null);
  });

  test('移动端保存二维码到相册', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(galChannel, (call) async {
          calls.add(call);
          if (call.method == 'requestPermission') return true;
          return null;
        });

    expect(await saveQrImage(_qrFor('test')), isTrue);
    expect(calls.map((call) => call.method), contains('putImageBytes'));
  });

  test('桌面端保存二维码 PNG 文件', () async {
    final directory = await Directory.systemTemp.createTemp('olivos_qr_save_');
    addTearDown(() => directory.delete(recursive: true));
    final path = p.join(directory.path, 'config-qr.png');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getSavePath');
          return path;
        });
    final data = ConfigTransfer.encode([
      const InstanceConfigEntry(
        name: '测试',
        baseUrl: testBaseUrl,
        autoLogin: false,
      ),
    ]);

    expect(await saveQrImage(_qrFor(data)), isTrue);
    expect(File(path).existsSync(), isTrue);
    expect(await decodeQrCodeFromImage(path), data);
  });

  test('取消保存对话框时不写文件', () async {
    final directory = await Directory.systemTemp.createTemp('olivos_qr_save_');
    addTearDown(() => directory.delete(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);

    expect(await saveQrImage(_qrFor('test')), isFalse);
    expect(directory.listSync(), isEmpty);
  });
}
