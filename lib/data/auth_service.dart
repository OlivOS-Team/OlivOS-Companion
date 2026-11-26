import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> login({
    required String baseUrl,
    required String password,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/api/login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final token = decoded['browser_token'];
        if (token is String && token.startsWith('webui.')) {
          return token;
        }
      }
      throw const AuthException('登录响应格式不正确');
    }
    if (response.statusCode == 401) {
      throw const AuthException('密码不正确或登录凭据已失效');
    }
    if (response.statusCode == 429) {
      throw const AuthException('尝试次数过多，请稍后再试');
    }
    throw AuthException('登录失败（HTTP ${response.statusCode}）');
  }

  /// WebUI 在启动时读取这个 key；只对实例自身的 origin 生效。
  String injectionScript({required String origin, required String token}) {
    final originLiteral = jsonEncode(origin);
    final tokenLiteral = jsonEncode(token);
    return '''
(function () {
  try {
    if (location.origin === $originLiteral) {
      localStorage.setItem('olivos.webui.token', $tokenLiteral);
    }
  } catch (_) {}
})();
''';
  }
}
