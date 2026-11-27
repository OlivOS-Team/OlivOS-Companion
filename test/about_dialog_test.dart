import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:olivos_companion/app/theme.dart';
import 'package:olivos_companion/features/about/about_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('关于对话框展示版本、归属和许可证', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'OlivOS Companion',
      packageName: 'com.olivosteam.olivos_companion',
      version: '0.1.6',
      buildNumber: '7',
      buildSignature: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildOlivOSTheme(Brightness.light),
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

    await tester.tap(find.text('打开关于'));
    await tester.pumpAndSettle();

    expect(find.text('关于 OlivOS Companion'), findsOneWidget);
    expect(find.text('版本 0.1.6+7'), findsOneWidget);
    expect(find.textContaining('OlivOS-Team'), findsWidgets);
    expect(find.textContaining('AGPL-3.0'), findsOneWidget);
    expect(find.byKey(const Key('about-agpl-link')), findsOneWidget);
    expect(find.byKey(const Key('about-project-link')), findsOneWidget);
    expect(find.textContaining('世界是属于每一个人的'), findsOneWidget);

    await tester.tap(find.byKey(const Key('about-version-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('component-licenses-page')), findsOneWidget);
    expect(find.text('组件与许可证'), findsOneWidget);
    expect(find.text('OlivOS Companion 0.1.6+7'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('关于 OlivOS Companion'), findsOneWidget);

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('关于 OlivOS Companion'), findsNothing);
  });
}
