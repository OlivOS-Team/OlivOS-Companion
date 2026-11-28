import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:olivos_companion/app/theme.dart';
import 'package:olivos_companion/features/about/about_dialog.dart';
import 'package:olivos_companion/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'support/app_version.dart';
import 'support/test_fixtures.dart';

void main() {
  final appVersion = AppVersionFixture.load();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: testAppName,
      packageName: testPackageName,
      version: appVersion.version,
      buildNumber: appVersion.buildNumber,
      buildSignature: '',
    );
  });

  testWidgets('关于对话框展示版本、归属和许可证', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await _openAbout(tester);

    expect(find.text('关于 OlivOS Companion'), findsOneWidget);
    expect(find.text('版本 ${appVersion.fullVersion}'), findsOneWidget);
    expect(find.textContaining('OlivOS-Team'), findsWidgets);
    expect(find.textContaining('AGPL-3.0'), findsOneWidget);
    expect(find.byKey(const Key('about-agpl-link')), findsOneWidget);
    expect(find.byKey(const Key('about-project-link')), findsOneWidget);
    expect(find.textContaining('世界是属于每一个人的'), findsOneWidget);

    await tester.tap(find.byKey(const Key('about-version-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('component-licenses-page')), findsOneWidget);
    expect(find.text('组件与许可证'), findsOneWidget);
    expect(
      find.text('OlivOS Companion ${appVersion.fullVersion}'),
      findsOneWidget,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('关于 OlivOS Companion'), findsOneWidget);

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('关于 OlivOS Companion'), findsNothing);
  });

  testWidgets('连续点击关于页 logo 开启彩蛋并重播开屏动画', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await _openAbout(tester);

    final logo = find.byKey(const Key('about-easter-egg-logo'));
    for (var i = 0; i < 4; i++) {
      await tester.tap(logo);
      await tester.pump();
    }
    expect(find.byKey(const Key('about-easter-egg-bubble')), findsNothing);

    const messages = [
      '还差 5 次',
      '开发者模式正在热身，还差 4 次',
      '仑质在门后数数，还差 3 次',
      '海内存知己，天涯若比邻。还差 2 次',
      '剑阁峥嵘而崔嵬，还差 1 次',
    ];
    for (final message in messages) {
      await tester.tap(logo);
      await tester.pump();
      expect(find.text(message), findsOneWidget);
    }

    await tester.pumpAndSettle();
    final bubble = find.byKey(const Key('about-easter-egg-bubble'));
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(tester.getBottomRight(bubble).dy, greaterThan(screenHeight * 0.8));

    await tester.tap(logo);
    await tester.pump();
    expect(find.byKey(const Key('launch-splash')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('launch-splash')), findsNothing);
    expect(find.text('关于 OlivOS Companion'), findsOneWidget);

    await tester.tap(logo);
    await tester.pump();
    expect(find.byKey(const Key('launch-splash')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('launch-splash')), findsNothing);
  });

  testWidgets('彩蛋倒数气泡支持英文', (tester) async {
    await tester.pumpWidget(_buildTestApp(locale: const Locale('en')));
    await _openAbout(tester);

    final logo = find.byKey(const Key('about-easter-egg-logo'));
    for (var i = 0; i < 4; i++) {
      await tester.tap(logo);
      await tester.pump();
    }
    expect(find.byKey(const Key('about-easter-egg-bubble')), findsNothing);

    const messages = [
      '5 taps to go',
      'Developer mode is warming up — 4 taps to go',
      'lunzhiPenxil is counting behind the door — 3 taps to go',
      'If you have friends who know your heart, '
          'distance cannot keep you apart. 2 taps to go',
      'The Sword Pass, steep and sheer. 1 tap to go',
    ];
    for (final message in messages) {
      await tester.tap(logo);
      await tester.pump();
      expect(find.text(message), findsOneWidget);
    }

    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const Key('about-easter-egg-bubble')), findsNothing);
  });

  testWidgets('关于页支持英文并使用俄语格言', (tester) async {
    await tester.pumpWidget(_buildTestApp(locale: const Locale('en')));
    await _openAbout(tester);

    expect(find.text('About OlivOS Companion'), findsOneWidget);
    expect(find.text('OlivOS multi-instance tray client'), findsOneWidget);
    expect(find.text('Witness Union / 见证联合 '), findsOneWidget);
    expect(find.text('Attribution'), findsOneWidget);
    expect(find.text('License'), findsOneWidget);
    expect(
      find.textContaining('This project is released under the GNU Affero'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Мир, принадлежащий всем и каждому'),
      findsOneWidget,
    );
    expect(find.textContaining('А. Бабуров'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/branding/olivos.png',
      ),
      findsOneWidget,
    );
    expect(find.text('Close'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('About OlivOS Companion'), findsNothing);
  });

  testWidgets('彩蛋倒数气泡颜色跟随明暗模式', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await _openAbout(tester);

    final logo = find.byKey(const Key('about-easter-egg-logo'));
    for (var i = 0; i < 5; i++) {
      await tester.tap(logo);
      await tester.pump();
    }

    final bubble = find.byKey(const Key('about-easter-egg-bubble'));
    final bubbleMaterial = tester.widget<Material>(bubble);
    final lightScheme = buildOlivOSTheme(Brightness.light).colorScheme;
    expect(bubbleMaterial.color, lightScheme.surface);
    expect(bubbleMaterial.color, isNot(lightScheme.inverseSurface));

    await tester.pumpWidget(_buildTestApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    final darkScheme = buildOlivOSTheme(Brightness.dark).colorScheme;
    expect(tester.widget<Material>(bubble).color, darkScheme.surface);
    expect(
      tester.widget<Material>(bubble).color,
      isNot(darkScheme.inverseSurface),
    );
    final text = tester.widget<Text>(find.text('还差 5 次'));
    expect(text.style?.color, darkScheme.onSurface);

    await tester.pump(const Duration(seconds: 3));
  });
}

Widget _buildTestApp({
  Locale locale = const Locale('zh', 'CN'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        ...GlobalMaterialLocalizations.delegates,
        AppLocalizations.delegate,
      ],
      theme: buildOlivOSTheme(Brightness.light),
      darkTheme: buildOlivOSTheme(Brightness.dark),
      themeMode: themeMode,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showOlivOSCompanionAboutDialog(context),
            child: const Text('打开关于'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openAbout(WidgetTester tester) async {
  await tester.tap(find.text('打开关于'));
  await tester.pumpAndSettle();
}
