import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:olivos_companion/app/theme.dart';
import 'package:olivos_companion/features/about/about_dialog.dart';

void main() {
  testWidgets('关于对话框展示归属和许可证', (tester) async {
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
    expect(find.textContaining('OlivOS-Team'), findsWidgets);
    expect(find.textContaining('AGPL-3.0'), findsOneWidget);
    expect(find.textContaining('世界是属于每一个人的'), findsOneWidget);

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('关于 OlivOS Companion'), findsNothing);
  });
}
