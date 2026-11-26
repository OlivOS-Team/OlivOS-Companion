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
          authError = '$error';
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
    final scheme = Theme.of(context).colorScheme;
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
            style: FilledButton.styleFrom(
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error.withValues(alpha: 0.35)),
            ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.profile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.profile.baseUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: () => _controller?.reload(),
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'browser',
                child: Row(
                  children: [
                    Icon(Icons.open_in_browser, size: 18),
                    SizedBox(width: 8),
                    Text('在浏览器打开'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Text('清除会话', style: TextStyle(color: colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _preparing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_authError != null)
                  _Notice(
                    message: '自动登录失败：$_authError。已回退到 WebUI 登录页。',
                    icon: Icons.error_outline,
                    background: colorScheme.errorContainer,
                    border: colorScheme.error.withValues(alpha: 0.35),
                    foreground: colorScheme.onErrorContainer,
                  ),
                if (_loadError != null)
                  _Notice(
                    message: _loadError!,
                    icon: Icons.info_outline,
                    background: colorScheme.surfaceContainerHighest,
                    border: colorScheme.outline,
                    foreground: colorScheme.onSurface,
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
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 2,
                            backgroundColor: colorScheme.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.message,
    required this.icon,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final String message;
  final IconData icon;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
