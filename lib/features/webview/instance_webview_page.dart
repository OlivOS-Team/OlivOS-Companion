import 'dart:collection';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/auth_service.dart';
import '../../data/instance_store.dart';
import '../../models/instance_profile.dart';

/// WebUI 的退出登录是页面内按钮；点击后通知原生页面退出。
const _webUiLogoutBridge = r'''
(function () {
  if (window.__olivosLogoutBound) return;
  window.__olivosLogoutBound = true;
  document.addEventListener('click', function (event) {
    var target = event.target;
    if (!target || !target.closest) return;
    if (!target.closest('#logout, button[aria-label="退出登录"]')) return;
    try {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('olivosLogout');
      }
    } catch (_) {}
  }, true);
})();
''';

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
  bool _logoutHandled = false;

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

  Future<void> _handleBack() async {
    if (_controller != null && await _controller!.canGoBack()) {
      await _controller!.goBack();
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _handleWebUiLogout() async {
    if (_logoutHandled) return;
    _logoutHandled = true;
    // 给 WebUI 的 /api/logout 一点时间完成，然后回到实例列表。
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: _preparing
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    Column(
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
                                initialUserScripts:
                                    UnmodifiableListView<UserScript>([
                                      if (_tokenScript != null)
                                        UserScript(
                                          source: _tokenScript!,
                                          injectionTime: UserScriptInjectionTime
                                              .AT_DOCUMENT_START,
                                        ),
                                    ]),
                                onWebViewCreated: (controller) {
                                  _controller = controller;
                                  controller.addJavaScriptHandler(
                                    handlerName: 'olivosLogout',
                                    callback: (args) {
                                      _handleWebUiLogout();
                                      return null;
                                    },
                                  );
                                },
                                onLoadStart: (controller, url) {
                                  setState(() => _loadError = null);
                                },
                                onLoadStop: (controller, url) {
                                  setState(() {
                                    _progress = 1;
                                    _loadError = null;
                                  });
                                  controller.evaluateJavascript(
                                    source: _webUiLogoutBridge,
                                  );
                                },
                                onProgressChanged: (controller, progress) {
                                  setState(() => _progress = progress / 100);
                                },
                                onReceivedError: (controller, request, error) {
                                  if (request.isForMainFrame ?? false) {
                                    setState(() {
                                      _loadError =
                                          '页面加载失败：${error.description}';
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
                    Positioned(
                      right: 12,
                      bottom: MediaQuery.paddingOf(context).bottom + 12,
                      child: _OverlayControls(
                        onBack: _handleBack,
                        onRefresh: () => _controller?.reload(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _OverlayControls extends StatelessWidget {
  const _OverlayControls({required this.onBack, required this.onRefresh});

  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.94),
      elevation: 1,
      shadowColor: theme.shadowColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '返回',
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
          Container(width: 1, height: 18, color: scheme.outlineVariant),
          IconButton(
            tooltip: '刷新',
            onPressed: onRefresh,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            icon: const Icon(Icons.refresh, size: 20),
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
