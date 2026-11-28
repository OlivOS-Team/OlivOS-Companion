import 'dart:async';
import 'dart:collection';

import 'package:flutter/scheduler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/auth_service.dart';
import '../../data/instance_store.dart';
import '../../data/web_view_environment.dart';
import '../../core/window_theme_service.dart';
import '../../l10n/app_error_localizations.dart';
import '../../l10n/app_localizations.dart';
import '../../models/instance_profile.dart';
import '../../state/theme_mode_provider.dart';
import '../about/easter_egg_mode.dart';

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

/// WebUI 的主题切换按钮会修改 html[data-theme]，观察它并同步回应用。
const _webUiThemeBridge = r'''
(function () {
  if (window.__olivosThemeBound) return;
  window.__olivosThemeBound = true;

  function reportTheme() {
    var theme = document.documentElement.dataset.theme;
    if (theme !== 'light' && theme !== 'dark') return;
    try {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('olivosThemeChanged', theme);
      }
    } catch (_) {}
  }

  new MutationObserver(reportTheme).observe(document.documentElement, {
    attributes: true,
    attributeFilter: ['data-theme'],
  });
})();
''';

/// Easter-egg diagnostics: reports the WebUI's requestAnimationFrame rate.
const _webUiFpsBridge = r'''
(function () {
  if (window.__olivosFpsBound) return;
  window.__olivosFpsBound = true;
  var frames = 0;
  var last = performance.now();
  function report(now) {
    frames++;
    var elapsed = now - last;
    if (elapsed >= 1000) {
      try {
        window.flutter_inappwebview.callHandler(
          'olivosFps',
          frames * 1000 / elapsed
        );
      } catch (_) {}
      frames = 0;
      last = now;
    }
    requestAnimationFrame(report);
  }
  requestAnimationFrame(report);
})();
''';

class InstanceWebViewPage extends ConsumerStatefulWidget {
  const InstanceWebViewPage({super.key, required this.profile});

  final InstanceProfile profile;

  @override
  ConsumerState<InstanceWebViewPage> createState() =>
      _InstanceWebViewPageState();
}

class _InstanceWebViewPageState extends ConsumerState<InstanceWebViewPage>
    with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final InstanceStore _store = InstanceStore();

  InAppWebViewController? _controller;
  WebViewEnvironment? _webViewEnvironment;
  String? _token;
  AuthFailure? _authFailure;
  int? _authStatusCode;
  String? _authErrorDetail;
  String? _loadError;
  bool _preparing = true;
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);
  bool _logoutHandled = false;
  bool _diagnosticsEnabled = false;
  double? _webFps;
  double? _uiFps;
  int? _monitorHz;
  bool _refreshRatePending = false;
  Timer? _refreshRateTimer;
  int _uiFrameCount = 0;
  final Stopwatch _uiFpsWindow = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    _diagnosticsEnabled = ref.read(easterEggModeProvider);
    if (_diagnosticsEnabled) {
      SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
      WidgetsBinding.instance.addObserver(this);
      unawaited(_refreshMonitorHz());
      _refreshRateTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(_refreshMonitorHz()),
      );
    }
    _prepare();
  }

  @override
  void dispose() {
    if (_diagnosticsEnabled) {
      SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
      WidgetsBinding.instance.removeObserver(this);
      _refreshRateTimer?.cancel();
    }
    _progress.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    unawaited(_refreshMonitorHz());
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!mounted) return;
    _uiFrameCount += timings.length;
    final elapsed = _uiFpsWindow.elapsed;
    if (elapsed < const Duration(seconds: 1)) return;
    final fps = _uiFrameCount * 1000 / elapsed.inMilliseconds;
    _uiFrameCount = 0;
    _uiFpsWindow.reset();
    setState(() => _uiFps = fps);
  }

  Future<void> _refreshMonitorHz() async {
    if (!_diagnosticsEnabled || _refreshRatePending) return;
    _refreshRatePending = true;
    try {
      final hz = await WindowThemeService.refreshRate();
      if (!mounted || hz == null || hz == _monitorHz) return;
      setState(() => _monitorHz = hz);
    } finally {
      _refreshRatePending = false;
    }
  }

  void _onWebFps(Object? value) {
    if (!mounted || value is! num) return;
    setState(() => _webFps = value.toDouble());
  }

  Future<void> _prepare() async {
    AuthFailure? authFailure;
    int? authStatusCode;
    String? authErrorDetail;
    String? token;

    unawaited(_cacheVersion());
    final webViewEnvironmentFuture = WebViewEnvironmentService.ensure();

    if (widget.profile.autoLogin) {
      final password = await _store.readPassword(widget.profile.id);
      if (password != null && password.isNotEmpty) {
        try {
          token = await _authService.login(
            baseUrl: widget.profile.baseUrl,
            password: password,
          );
        } on AuthException catch (error) {
          authFailure = error.failure;
          authStatusCode = error.statusCode;
        } catch (error) {
          authErrorDetail = '$error';
        }
      }
    }

    final webViewEnvironment = await webViewEnvironmentFuture;
    if (!mounted) return;
    setState(() {
      _preparing = false;
      _webViewEnvironment = webViewEnvironment;
      _token = token;
      _authFailure = authFailure;
      _authStatusCode = authStatusCode;
      _authErrorDetail = authErrorDetail;
    });
  }

  Future<void> _cacheVersion() async {
    final version = await _authService.fetchVersion(
      baseUrl: widget.profile.baseUrl,
    );
    if (version == null) return;
    await _store.saveVersion(
      id: widget.profile.id,
      version: version.version,
      versionSlogan: version.slogan,
    );
  }

  Future<void> _openExternal(Uri uri) async {
    if (!await canLaunchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).openLinkFailed('$uri')),
        ),
      );
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

  Future<void> _syncThemeFromWebUi(String theme) async {
    if (!mounted) return;
    await ref
        .read(themeModeProvider.notifier)
        .setThemeMode(theme == 'dark' ? ThemeMode.dark : ThemeMode.light);
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
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final authErrorDetail = _authFailure != null
        ? l10n.authFailureMessage(_authFailure!, statusCode: _authStatusCode)
        : _authErrorDetail;
    final userScript = _authService.injectionScript(
      origin: widget.profile.origin,
      token: _token,
      darkMode: Theme.of(context).brightness == Brightness.dark,
    );
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
                        if (authErrorDetail != null)
                          _Notice(
                            message: l10n.autoLoginFailed(authErrorDetail),
                            icon: Icons.error_outline,
                            background: colorScheme.errorContainer,
                            border: colorScheme.error.withValues(alpha: 0.35),
                            foreground: colorScheme.onErrorContainer,
                          ),
                        if (_loadError != null)
                          _Notice(
                            message: l10n.pageLoadFailed(_loadError!),
                            icon: Icons.info_outline,
                            background: colorScheme.surfaceContainerHighest,
                            border: colorScheme.outline,
                            foreground: colorScheme.onSurface,
                          ),
                        Expanded(
                          child: Stack(
                            children: [
                              InAppWebView(
                                webViewEnvironment: _webViewEnvironment,
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
                                      UserScript(
                                        source: userScript,
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
                                  controller.addJavaScriptHandler(
                                    handlerName: 'olivosThemeChanged',
                                    callback: (args) {
                                      final theme = args.isNotEmpty
                                          ? args.first
                                          : null;
                                      if (theme == 'dark' || theme == 'light') {
                                        _syncThemeFromWebUi(theme as String);
                                      }
                                      return null;
                                    },
                                  );
                                  if (_diagnosticsEnabled) {
                                    controller.addJavaScriptHandler(
                                      handlerName: 'olivosFps',
                                      callback: (args) {
                                        _onWebFps(
                                          args.isNotEmpty ? args.first : null,
                                        );
                                        return null;
                                      },
                                    );
                                  }
                                },
                                onLoadStart: (controller, url) {
                                  if (_loadError != null) {
                                    setState(() => _loadError = null);
                                  }
                                },
                                onLoadStop: (controller, url) {
                                  _progress.value = 1;
                                  if (_loadError != null) {
                                    setState(() => _loadError = null);
                                  }
                                  controller.evaluateJavascript(
                                    source: _webUiLogoutBridge,
                                  );
                                  controller.evaluateJavascript(
                                    source: _webUiThemeBridge,
                                  );
                                  if (_diagnosticsEnabled) {
                                    controller.evaluateJavascript(
                                      source: _webUiFpsBridge,
                                    );
                                  }
                                },
                                onProgressChanged: (controller, progress) {
                                  _progress.value = progress / 100;
                                },
                                onReceivedError: (controller, request, error) {
                                  if (request.isForMainFrame ?? false) {
                                    setState(() {
                                      _loadError = error.description;
                                    });
                                  }
                                },
                                shouldOverrideUrlLoading: _handleNavigation,
                                onCreateWindow: _handleCreateWindow,
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: ValueListenableBuilder<double>(
                                  valueListenable: _progress,
                                  builder: (context, progress, _) {
                                    if (progress <= 0 || progress >= 1) {
                                      return const SizedBox.shrink();
                                    }
                                    return LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 2,
                                      backgroundColor:
                                          colorScheme.outlineVariant,
                                    );
                                  },
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_diagnosticsEnabled) ...[
                            _WebViewDiagnostics(
                              webFps: _webFps,
                              uiFps: _uiFps,
                              monitorHz: _monitorHz,
                            ),
                            const SizedBox(width: 8),
                          ],
                          _OverlayControls(
                            onBack: _handleBack,
                            onRefresh: () => _controller?.reload(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _WebViewDiagnostics extends StatelessWidget {
  const _WebViewDiagnostics({
    required this.webFps,
    required this.uiFps,
    required this.monitorHz,
  });

  final double? webFps;
  final double? uiFps;
  final int? monitorHz;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final web = webFps?.toStringAsFixed(0) ?? '--';
    final ui = uiFps?.toStringAsFixed(0) ?? '--';
    final hz = monitorHz?.toString() ?? '--';
    return Material(
      key: const Key('webview-easter-egg-diagnostics'),
      color: scheme.surface.withValues(alpha: 0.94),
      elevation: 1,
      shadowColor: theme.shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          'WEB $web  UI $ui  HZ $hz',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
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
    final l10n = AppLocalizations.of(context);
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
            tooltip: l10n.back,
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
          Container(width: 1, height: 18, color: scheme.outlineVariant),
          IconButton(
            tooltip: l10n.refresh,
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
