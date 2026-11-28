import 'dart:convert';

import 'package:http/http.dart' as http;

enum AuthFailure {
  malformedResponse,
  invalidCredentials,
  rateLimited,
  httpError,
}

class AuthException implements Exception {
  const AuthException(this.failure, {this.statusCode, this.cause});

  final AuthFailure failure;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() =>
      'AuthException(${failure.name}, statusCode: $statusCode, cause: $cause)';
}

class OlivOSVersion {
  const OlivOSVersion({required this.version, this.slogan});

  final String version;
  final String? slogan;
}

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Reads the public version block from the WebUI health endpoint.
  ///
  /// This endpoint intentionally does not require a token; failures are
  /// non-fatal because the cached version is only decorative.
  Future<OlivOSVersion?> fetchVersion({required String baseUrl}) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return null;

      final version = decoded['version'];
      if (version is! String || version.trim().isEmpty) return null;

      final rawSlogan = decoded['version_slogan'];
      final slogan = rawSlogan is String ? rawSlogan.trim() : '';
      return OlivOSVersion(
        version: version.trim(),
        slogan: slogan.isEmpty ? null : slogan,
      );
    } catch (_) {
      return null;
    }
  }

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
      throw const AuthException(AuthFailure.malformedResponse);
    }
    if (response.statusCode == 401) {
      throw const AuthException(AuthFailure.invalidCredentials);
    }
    if (response.statusCode == 429) {
      throw const AuthException(AuthFailure.rateLimited);
    }
    throw AuthException(AuthFailure.httpError, statusCode: response.statusCode);
  }

  /// WebUI 在启动时读取这个 key；只对实例自身的 origin 生效。
  String injectionScript({
    required String origin,
    String? token,
    bool? darkMode,
  }) {
    final originLiteral = jsonEncode(origin);
    final tokenLine = token == null || token.isEmpty
        ? ''
        : "localStorage.setItem('olivos.webui.token', ${jsonEncode(token)});";
    final themeLine = darkMode == null
        ? ''
        : "localStorage.setItem('olivos.webui.theme', '${darkMode ? 'dark' : 'light'}');";
    return '''
(function () {
  try {
    if (location.origin === $originLiteral) {
      $themeLine
      $tokenLine
    }
  } catch (_) {}
})();
''';
  }
}
