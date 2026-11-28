import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:olivos_companion/data/auth_service.dart';

import 'support/test_fixtures.dart';

void main() {
  test('login 发送密码并返回 browser_token', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), '$testBaseUrl/api/login');
      expect(request.headers['content-type'], startsWith('application/json'));
      expect(jsonDecode(request.body), {'password': testPassword});
      return http.Response(
        jsonEncode({'browser_token': 'webui.abc'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final token = await AuthService(client: client)
        .login(baseUrl: testBaseUrl, password: testPassword);

    expect(token, 'webui.abc');
  });

  test('401 映射为密码错误', () async {
    final client = MockClient((request) async => http.Response('', 401));

    expect(
      () =>
          AuthService(client: client)
              .login(baseUrl: testBaseUrl, password: 'wrong'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.failure,
          'failure',
          AuthFailure.invalidCredentials,
        ),
      ),
    );
  });

  test('429 映射为限流提示', () async {
    final client = MockClient((request) async => http.Response('', 429));

    expect(
      () =>
          AuthService(client: client)
              .login(baseUrl: testBaseUrl, password: testPassword),
      throwsA(
        isA<AuthException>().having(
          (error) => error.failure,
          'failure',
          AuthFailure.rateLimited,
        ),
      ),
    );
  });

  test('fetchVersion 读取公开的 /api/health 版本信息', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), '$testBaseUrl/api/health');
      return http.Response(
        jsonEncode({
          'status': 'OK',
          'version': testWebUiVersion,
          'version_slogan': testWebUiSlogan,
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final version = await AuthService(client: client)
        .fetchVersion(baseUrl: testBaseUrl);

    expect(version?.version, testWebUiVersion);
    expect(version?.slogan, testWebUiSlogan);
  });

  test('fetchVersion 在接口异常时返回 null', () async {
    final client = MockClient((request) async => http.Response('', 503));

    final version = await AuthService(client: client)
        .fetchVersion(baseUrl: testBaseUrl);

    expect(version, isNull);
  });

  test('注入脚本会同步 WebUI 主题', () {
    final script = AuthService().injectionScript(
      origin: testBaseUrl,
      darkMode: true,
    );

    expect(script, contains('olivos.webui.theme'));
    expect(script, contains("'dark'"));
  });

  test('注入脚本限定 origin 并写入 token key', () {
    final script = AuthService().injectionScript(
      origin: testBaseUrl,
      token: 'webui.abc',
    );

    expect(script, contains('"$testBaseUrl"'));
    expect(script, contains('olivos.webui.token'));
    expect(script, contains('"webui.abc"'));
  });
}
