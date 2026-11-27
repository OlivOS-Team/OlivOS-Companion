import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/data/config_transfer.dart';
import 'package:qr/qr.dart';

void main() {
  test('单个实例配置可以编码为二维码', () {
    final encoded = ConfigTransfer.encode([
      const InstanceConfigEntry(
        name: '测试实例',
        baseUrl: 'http://127.0.0.1:20480',
        autoLogin: true,
        password: 'password',
      ),
    ]);

    final code = QrCode(
      payload: QrPayload.fromString(encoded),
      errorCorrectLevel: QrErrorCorrectLevel.low,
    );
    final image = QrImage(code);

    expect(code.moduleCount, greaterThanOrEqualTo(21));
    expect(image.isDark(0, 0), isTrue);
  });
}
