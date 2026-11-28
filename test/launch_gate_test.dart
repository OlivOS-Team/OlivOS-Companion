import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:olivos_companion/features/startup/launch_gate.dart';
import 'package:olivos_companion/features/startup/olivos_mark.dart';
import 'package:olivos_companion/l10n/app_localizations.dart';

void main() {
  test('1、2 号线使用单个多边形并保留末端出屏', () {
    for (final id in [1, 2]) {
      final line = olivosMarkLines.firstWhere((line) => line.id == id);
      expect(line.polygons, hasLength(1));
      expect(line.extendEnd, isTrue);
    }
  });

  testWidgets('启动动画结束后进入主界面', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          ...GlobalMaterialLocalizations.delegates,
          AppLocalizations.delegate,
        ],
        home: const LaunchGate(child: Scaffold(body: Text('主界面'))),
      ),
    );

    expect(find.byKey(const Key('launch-splash')), findsOneWidget);
    expect(find.text('主界面'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('launch-splash')), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('launch-splash')), findsNothing);
    expect(find.text('主界面'), findsOneWidget);
  });

  testWidgets('禁用动画时直接显示主界面', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          ...GlobalMaterialLocalizations.delegates,
          AppLocalizations.delegate,
        ],
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: LaunchGate(child: Scaffold(body: Text('主界面'))),
        ),
      ),
    );

    expect(find.byKey(const Key('launch-splash')), findsNothing);
    expect(find.text('主界面'), findsOneWidget);
  });
}
