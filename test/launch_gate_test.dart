import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:olivos_companion/features/startup/launch_gate.dart';

void main() {
  testWidgets('启动动画结束后进入主界面', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LaunchGate(child: Scaffold(body: Text('主界面'))),
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
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: LaunchGate(child: Scaffold(body: Text('主界面'))),
        ),
      ),
    );

    expect(find.byKey(const Key('launch-splash')), findsNothing);
    expect(find.text('主界面'), findsOneWidget);
  });
}
