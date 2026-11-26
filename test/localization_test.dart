import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('Material 菜单按钮提示使用中文', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) =>
              Text(MaterialLocalizations.of(context).showMenuTooltip),
        ),
      ),
    );

    expect(find.text('显示菜单'), findsOneWidget);
  });
}
