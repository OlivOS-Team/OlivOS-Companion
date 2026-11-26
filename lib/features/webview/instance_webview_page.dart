import 'dart:collection';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/auth_service.dart';
import '../../data/instance_store.dart';
import '../../models/instance_profile.dart';

class InstanceWebViewPage extends StatefulWidget {
  const InstanceWebViewPage({super.key, required this.profile});

  final InstanceProfile profile;

  @override
  State<InstanceWebViewPage> createState() => _InstanceWebViewPageState();
}

class _InstanceWebViewPageState extends State<InstanceWebViewPage> {
  final AuthService _authService = AuthService();
  final InstanceStore _store = InstanceStore();

  InAppWebViewController? _controller;
  String? _tokenScript;
  String? _authError;
  String? _loadError;
  bool _preparing = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    String? authError;
    String? tokenScript;

    if (widget.profile.autoLogin) {
      final password = await _store.readPassword(widget.profile.id);
      if (password != null && password.isNotEmpty) {
        try {
          final token = await _authService.login(
            baseUrl: widget.profile.baseUrl,
            password: password,
          );
          tokenScript = _authService.injectionScript(
            origin: widget.profile.origin,
            token: token,
          );
        } on AuthException catch (error) {
          authError = error.message;
        } catch (error) {
          authError = '自动登录失败：$error';
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _preparing = false;
      _tokenScript = tokenScript;
      _authError = authError;
    });
  }

  Future<void> _openExternal(Uri uri) async {
    if (!await canLaunchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('无法打开链接：$uri')));
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<NavigationActionPolicy?> _handleNavigation(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final url = action.request.url;
    if (url == null) return NavigationActionPolicy.ALLOW;

    final uri = Uri.parse(url.toString());
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return NavigationActionPolicy.ALLOW;
    }
    if (uri.origin != widget.profile.origin) {
      await _openExternal(uri);
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  Future<bool?> _handleCreateWindow(
    InAppWebViewController controller,
    CreateWindowAction action,
  ) async {
    final url = action.request.url;
    if (url != null) {
      await _openExternal(Uri.parse(url.toString()));
    }
    return false;
  }

  Future<void> _clearSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除会话'),
        content: const Text('将清除该实例在应用内的登录状态，下次需要重新登录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _controller?.evaluateJavascript(
      source: 'localStorage.clear(); sessionStorage.clear();',
    );
    await InAppWebViewController.clearAllCache();
    await CookieManager.instance().deleteAllCookies();
    await _store.deletePassword(widget.profile.id);
    await _controller?.reload();
  }

  Future<void> _onMenuSelected(String value) async {
    switch (value) {
      case 'browser':
        await _openExternal(Uri.parse(widget.profile.baseUrl));
      case 'clear':
        await _clearSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.name),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () => _controller?.reload(),
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'browser', child: Text('在浏览器打开')),
              PopupMenuItem(value: 'clear', child: Text('清除会话')),
            ],
          ),
        ],
      ),
      body: _preparing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_authError != null)
                  _Banner(
                    message: '自动登录失败：$_authError。已回退到 WebUI 登录页。',
                    background: colorScheme.errorContainer,
                    foreground: colorScheme.onErrorContainer,
                  ),
                if (_loadError != null)
                  _Banner(
                    message: _loadError!,
                    background: colorScheme.secondaryContainer,
                    foreground: colorScheme.onSecondaryContainer,
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      InAppWebView(
                        initialUrlRequest: URLRequest(
                          url: WebUri(widget.profile.baseUrl),
                        ),
                        initialSettings: InAppWebViewSettings(
                          useShouldOverrideUrlLoading: true,
                          javaScriptEnabled: true,
                          domStorageEnabled: true,
                        ),
                        initialUserScripts: UnmodifiableListView<UserScript>([
                          if (_tokenScript != null)
                            UserScript(
                              source: _tokenScript!,
                              injectionTime:
                                  UserScriptInjectionTime.AT_DOCUMENT_START,
                            ),
                        ]),
                        onWebViewCreated: (controller) {
                          _controller = controller;
                        },
                        onLoadStart: (controller, url) {
                          setState(() => _loadError = null);
                        },
                        onLoadStop: (controller, url) {
                          setState(() {
                            _progress = 1;
                            _loadError = null;
                          });
                        },
                        onProgressChanged: (controller, progress) {
                          setState(() => _progress = progress / 100);
                        },
                        onReceivedError: (controller, request, error) {
                          if (request.isForMainFrame ?? false) {
                            setState(() {
                              _loadError = '页面加载失败：${error.description}';
                            });
                          }
                        },
                        shouldOverrideUrlLoading: _handleNavigation,
                        onCreateWindow: _handleCreateWindow,
                      ),
                      if (_progress > 0 && _progress < 1)
                        LinearProgressIndicator(value: _progress),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    required this.background,
    required this.foreground,
  });

  final String message;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(message, style: TextStyle(color: foreground)),
    );
  }
}
