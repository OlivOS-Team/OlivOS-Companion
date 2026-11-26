import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/data/config_transfer.dart';

void main() {
  const entry = InstanceConfigEntry(
    name: 'dev',
    baseUrl: 'http://127.0.0.1:20480',
    autoLogin: true,
    password: 'secret',
  );

  test('导出使用前缀和 Base64，并可往返解析', () {
    final encoded = ConfigTransfer.encode([entry]);

    expect(encoded.startsWith(configTransferPrefix), isTrue);
    expect(encoded.contains('secret'), isFalse);

    final decoded = ConfigTransfer.decode(encoded);
    expect(decoded, hasLength(1));
    expect(decoded.single.name, 'dev');
    expect(decoded.single.baseUrl, 'http://127.0.0.1:20480');
    expect(decoded.single.autoLogin, isTrue);
    expect(decoded.single.password, 'secret');
  });

  test('单个实例导出同样可用', () {
    final encoded = ConfigTransfer.encode([entry]);
    expect(ConfigTransfer.decode(encoded).single.name, 'dev');
  });

  test('拒绝缺少前缀的内容', () {
    expect(
      () => ConfigTransfer.decode(base64.encode(utf8.encode('{}'))),
      throwsA(isA<ConfigTransferException>()),
    );
  });

  test('拒绝损坏的 Base64', () {
    expect(
      () => ConfigTransfer.decode('${configTransferPrefix}not-base64'),
      throwsA(isA<ConfigTransferException>()),
    );
  });

  test('导入时会规范化实例地址', () {
    final payload = base64.encode(
      utf8.encode(
        jsonEncode({
          'format': 'olivos-companion-config',
          'version': 1,
          'instances': [
            {'name': 'dev', 'baseUrl': '127.0.0.1:20480/', 'autoLogin': false},
          ],
        }),
      ),
    );

    final decoded = ConfigTransfer.decode('$configTransferPrefix$payload');
    expect(decoded.single.baseUrl, 'http://127.0.0.1:20480');
    expect(decoded.single.autoLogin, isFalse);
  });
}
