/// URL 规范化：实例地址必须是 origin（scheme + host + port），
/// WebUI 使用绝对路径资源，不支持子路径部署。
String? normalizeBaseUrl(String input) {
  var value = input.trim();
  if (value.isEmpty) return null;
  if (!value.contains('://')) {
    value = 'http://$value';
  }

  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;
  if (uri.userInfo.isNotEmpty) return null;
  if (uri.hasQuery || uri.hasFragment) return null;
  if (uri.path.isNotEmpty && uri.path != '/') return null;

  return uri.replace(path: '', query: null, fragment: null).toString();
}

String originOf(String baseUrl) => Uri.parse(baseUrl).origin;
