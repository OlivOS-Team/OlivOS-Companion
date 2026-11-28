import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:olivos_companion/app/theme.dart';
import 'package:olivos_companion/features/about/component_licenses_page.dart';
import 'package:olivos_companion/features/about/component_versions.dart';
import 'package:olivos_companion/l10n/app_localizations.dart';

void main() {
  testWidgets('组件页面展示版本、开发依赖和许可证文本', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          ...GlobalMaterialLocalizations.delegates,
          AppLocalizations.delegate,
        ],
        theme: buildOlivOSTheme(Brightness.light),
        home: ComponentLicensesPage(
          applicationVersion: '0.2.2+9',
          versions: Future.value([
            const ComponentVersion(
              name: 'flutter_riverpod',
              version: '3.5.0',
              dependency: 'direct main',
            ),
            const ComponentVersion(
              name: 'dev_tool',
              version: '1.0.0',
              dependency: 'direct dev',
            ),
          ]),
          licenses: Future.value({
            'flutter_riverpod': [
              LicenseEntryWithLineBreaks(const [
                'flutter_riverpod',
              ], 'MIT License\n\nPermission is hereby granted.'),
            ],
            'license_only': [
              LicenseEntryWithLineBreaks(const [
                'license_only',
              ], 'Apache License'),
            ],
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('组件与许可证'), findsOneWidget);
    expect(find.text('OlivOS Companion 0.2.2+9'), findsOneWidget);
    expect(find.text('flutter_riverpod'), findsOneWidget);
    expect(find.text('版本 3.5.0'), findsOneWidget);
    expect(find.text('dev_tool'), findsOneWidget);
    expect(find.text('版本 1.0.0 · 开发依赖'), findsOneWidget);
    expect(find.text('license_only'), findsOneWidget);
    expect(find.text('版本未知'), findsNothing);
    expect(find.textContaining('本页面列出'), findsNothing);
    expect(find.textContaining('pubspec.lock'), findsNothing);

    await tester.tap(find.text('flutter_riverpod'));
    await tester.pumpAndSettle();

    expect(find.textContaining('MIT License'), findsOneWidget);
    expect(find.textContaining('Permission is hereby granted'), findsOneWidget);
  });
}
