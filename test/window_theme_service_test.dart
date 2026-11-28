import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/core/window_theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('olivos_companion/window');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('读取窗口所在显示器的刷新率', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getRefreshRate');
          return 120;
        });

    expect(await WindowThemeService.refreshRate(), 120);
  });

  test('无效刷新率返回 null', () async {
    for (final value in [null, 0, 1]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => value);

      expect(await WindowThemeService.refreshRate(), isNull);
    }
  });

  test('原生通道异常返回 null', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'unavailable');
        });

    expect(await WindowThemeService.refreshRate(), isNull);
  });

  test('平台未实现时返回 null', () async {
    expect(await WindowThemeService.refreshRate(), isNull);
  });
}
