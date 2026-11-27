import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:olivos_companion/app/theme.dart';
import 'package:olivos_companion/data/config_transfer.dart';
import 'package:olivos_companion/features/qr/qr_code_dialog.dart';

Widget _host(String data) {
  return MaterialApp(
    theme: buildOlivOSTheme(Brightness.light),
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () =>
              showConfigQrDialog(context, data: data, description: '全部实例（1 个）'),
          child: const Text('打开二维码'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('二维码对话框展示二维码和保存入口', (tester) async {
    final data = ConfigTransfer.encode([
      const InstanceConfigEntry(
        name: '测试',
        baseUrl: 'http://127.0.0.1:20480',
        autoLogin: false,
      ),
    ]);
    await tester.pumpWidget(_host(data));

    await tester.tap(find.text('打开二维码'));
    await tester.pumpAndSettle();

    expect(find.text('导出二维码'), findsOneWidget);
    expect(find.text('全部实例（1 个）'), findsOneWidget);
    expect(find.text('保存到本地'), findsOneWidget);
    expect(find.text('二维码包含自动登录密码，请仅用于自己的设备。'), findsOneWidget);

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('导出二维码'), findsNothing);
  });

  testWidgets('内容过长时提示无法生成二维码', (tester) async {
    await tester.pumpWidget(_host(List.filled(10000, 'x').join()));

    await tester.tap(find.text('打开二维码'));
    await tester.pumpAndSettle();

    expect(find.text('无法生成二维码'), findsOneWidget);
    expect(find.text('保存到本地'), findsNothing);
  });
}
