import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/core/url_utils.dart';

void main() {
  group('normalizeBaseUrl', () {
    test('补全 http 并去掉末尾斜杠', () {
      expect(normalizeBaseUrl('127.0.0.1:20480/'), 'http://127.0.0.1:20480');
    });

    test('保留 https 与端口', () {
      expect(
        normalizeBaseUrl('https://olivos.example.com:8443'),
        'https://olivos.example.com:8443',
      );
    });

    test('拒绝子路径', () {
      expect(normalizeBaseUrl('http://127.0.0.1:20480/webui'), isNull);
    });

    test('拒绝无效 scheme', () {
      expect(normalizeBaseUrl('ftp://127.0.0.1:20480'), isNull);
    });

    test('拒绝查询参数和 fragment', () {
      expect(normalizeBaseUrl('http://127.0.0.1:20480/?a=1'), isNull);
      expect(normalizeBaseUrl('http://127.0.0.1:20480/#x'), isNull);
    });
  });

  test('originOf 返回 origin', () {
    expect(originOf('http://127.0.0.1:20480'), 'http://127.0.0.1:20480');
  });
}
