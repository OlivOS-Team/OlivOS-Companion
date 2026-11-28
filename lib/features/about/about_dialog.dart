import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../startup/launch_gate.dart';
import 'component_licenses_page.dart';
import 'easter_egg_mode.dart';

const _agplUrl = 'https://www.gnu.org/licenses/agpl-3.0.html';
const _projectUrl = 'https://github.com/OlivOS-Team/OlivOS-Companion';

Future<void> showOlivOSCompanionAboutDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _AboutDialog(),
  );
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    Widget sectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 6),
        child: Text(
          title,
          style: textTheme.labelLarge?.copyWith(color: colors.primary),
        ),
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          const _EasterEggLogo(),
          const SizedBox(width: 12),
          const Expanded(child: Text('关于 OlivOS Companion')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OlivOS 多实例托盘 客户端', style: textTheme.titleSmall),
            const SizedBox(height: 6),
            const _VersionText(),
            const SizedBox(height: 8),
            Text('Witness Union / 见证联合 ', style: textTheme.bodyMedium),
            sectionTitle('归属'),
            Text(
              '本项目由 OlivOS-Team 维护，是独立的 OlivOS 生态客户端，与 '
              'OlivOS 本体分开构建和发布。本项目不修改 OlivOS 源代码。'
              'OlivOS 名称、图标及相关品牌归 OlivOS 项目及其贡献者所有。',
              style: textTheme.bodyMedium,
            ),
            sectionTitle('许可证'),
            Text.rich(
              TextSpan(
                style: textTheme.bodyMedium,
                children: [
                  const TextSpan(
                    text:
                        '本项目基于 GNU Affero General Public '
                        'License v3.0（',
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: _InlineLink(
                      key: const Key('about-agpl-link'),
                      label: 'AGPL-3.0',
                      uri: Uri.parse(_agplUrl),
                    ),
                  ),
                  const TextSpan(text: '）发布。'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('about-project-link'),
                onPressed: () => _openExternal(context, Uri.parse(_projectUrl)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: colors.primary,
                ),
                child: Text(
                  _projectUrl,
                  style: textTheme.bodySmall?.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('世界是属于每一个人的。要创造一个充满逻辑并尊重每一个人的世界。', style: textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              '——А. Бабуров, А. Гутнов, И. Лежава и др.'
              '《Новый элемент расселения: на пути к новому городу》. '
              'Москва: Стройиздат, A.D. 1966.',
              style: textTheme.labelSmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

Future<void> _openExternal(BuildContext context, Uri uri) async {
  try {
    if (await canLaunchUrl(uri)) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    }
  } catch (_) {
    // Fall through to the snackbar below.
  }
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text('无法打开链接：$uri')));
}

class _InlineLink extends StatelessWidget {
  const _InlineLink({super.key, required this.label, required this.uri});

  final String label;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    return Semantics(
      link: true,
      child: InkWell(
        onTap: () => _openExternal(context, uri),
        child: Text(label, style: style),
      ),
    );
  }
}

class _EasterEggLogo extends ConsumerStatefulWidget {
  const _EasterEggLogo();

  @override
  ConsumerState<_EasterEggLogo> createState() => _EasterEggLogoState();
}

class _EasterEggLogoState extends ConsumerState<_EasterEggLogo> {
  static const int _requiredTaps = 10;
  static const int _bubbleFrom = 5;
  static const Duration _bubbleDuration = Duration(milliseconds: 2000);

  OverlayEntry? _bubble;
  Timer? _bubbleTimer;
  int _remaining = _requiredTaps;

  @override
  void dispose() {
    _removeBubble();
    super.dispose();
  }

  void _removeBubble() {
    _bubbleTimer?.cancel();
    _bubbleTimer = null;
    final bubble = _bubble;
    _bubble = null;
    if (bubble?.mounted ?? false) {
      bubble!.remove();
    }
  }

  void _showBubble(String message) {
    _removeBubble();
    final entry = OverlayEntry(
      builder: (context) => _EasterEggBubble(message: message),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    _bubble = entry;
    _bubbleTimer = Timer(_bubbleDuration, _removeBubble);
  }

  void _handleTap() {
    if (ref.read(easterEggModeProvider)) {
      _removeBubble();
      _playEasterEgg();
      return;
    }
    if (_remaining <= 0) return;

    final remaining = _remaining - 1;
    setState(() => _remaining = remaining);
    if (remaining == 0) {
      _removeBubble();
      ref.read(easterEggModeProvider.notifier).enable();
      _playEasterEgg();
      return;
    }
    if (remaining <= _bubbleFrom) {
      _showBubble(
        AppLocalizations.of(context).easterEggTapsRemaining(remaining),
      );
    }
  }

  Future<void> _playEasterEgg() async {
    final navigator = Navigator.of(context, rootNavigator: true);
    await navigator.push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        barrierDismissible: false,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) {
          return LaunchGate(
            onFinished: () {
              if (navigator.canPop()) navigator.pop();
            },
            child: const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'OlivOS 品牌图标',
      child: InkWell(
        key: const Key('about-easter-egg-logo'),
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/branding/olivos.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _EasterEggBubble extends StatelessWidget {
  const _EasterEggBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: colors.onInverseSurface,
    );

    return Positioned.fill(
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 24 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Semantics(
                  liveRegion: true,
                  container: true,
                  child: Material(
                    key: const Key('about-easter-egg-bubble'),
                    color: colors.inverseSurface,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        message,
                        style: style,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionText extends StatefulWidget {
  const _VersionText();

  @override
  State<_VersionText> createState() => _VersionTextState();
}

class _VersionTextState extends State<_VersionText> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return FutureBuilder<PackageInfo>(
      future: _packageInfo,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        final info = snapshot.data;
        if (info == null) return Text('版本 …', style: style);
        final buildNumber = info.buildNumber.trim();
        final version = buildNumber.isEmpty
            ? info.version
            : '${info.version}+$buildNumber';
        final theme = Theme.of(context);
        final linkStyle = style?.copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        );
        return Align(
          alignment: Alignment.centerLeft,
          child: Tooltip(
            message: '查看组件版本与开源许可证',
            child: TextButton(
              key: const Key('about-version-button'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        ComponentLicensesPage(applicationVersion: version),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: theme.colorScheme.primary,
                textStyle: linkStyle,
              ),
              child: Text('版本 $version'),
            ),
          ),
        );
      },
    );
  }
}
