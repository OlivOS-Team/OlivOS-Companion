import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:olivos_companion/app/theme.dart';
import 'package:olivos_companion/data/config_transfer.dart';
import 'package:olivos_companion/features/instances/instance_list_page.dart';
import 'package:olivos_companion/models/instance_profile.dart';
import 'package:olivos_companion/state/instances_provider.dart';

import 'support/memory_instance_store.dart';

Widget _app(MemoryInstanceStore store) {
  return ProviderScope(
    overrides: [instanceStoreProvider.overrideWithValue(store)],
    child: MaterialApp(
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildOlivOSTheme(Brightness.light),
      darkTheme: buildOlivOSTheme(Brightness.dark),
      themeMode: ThemeMode.light,
      home: const InstanceListPage(),
    ),
  );
}

void main() {
  testWidgets('空状态使用从剪贴板导入的复用下拉菜单', (tester) async {
    final store = MemoryInstanceStore();
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();

    expect(find.text('还没有 OlivOS 实例'), findsOneWidget);
    expect(find.text('从剪贴板导入'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down).last);
    await tester.pumpAndSettle();

    expect(find.text('手动添加'), findsNothing);
    expect(find.text('从相册选择'), findsOneWidget);
  });

  testWidgets('批量模式导出只包含选中实例', (tester) async {
    final clipboardCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') clipboardCalls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final store = MemoryInstanceStore(
      initialProfiles: const [
        InstanceProfile(
          id: 'one',
          name: '实例一',
          baseUrl: 'http://127.0.0.1:20480',
        ),
        InstanceProfile(
          id: 'two',
          name: '实例二',
          baseUrl: 'http://127.0.0.1:20481',
        ),
      ],
    );
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.checklist));
    await tester.pumpAndSettle();
    await tester.tap(find.text('实例二'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.file_upload_outlined));
    await tester.pumpAndSettle();

    expect(clipboardCalls, hasLength(1));
    final text = (clipboardCalls.single.arguments as Map)['text'] as String;
    final entries = ConfigTransfer.decode(text);
    expect(entries, hasLength(1));
    expect(entries.single.name, '实例二');
    expect(find.textContaining('已导出选中的 1 个实例'), findsOneWidget);
  });

  testWidgets('批量模式可以选择并删除选中实例', (tester) async {
    final store = MemoryInstanceStore(
      initialProfiles: const [
        InstanceProfile(
          id: 'one',
          name: '实例一',
          baseUrl: 'http://127.0.0.1:20480',
        ),
        InstanceProfile(
          id: 'two',
          name: '实例二',
          baseUrl: 'http://127.0.0.1:20481',
        ),
      ],
    );
    await tester.pumpWidget(_app(store));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.checklist));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNWidgets(2));
    expect(find.text('已选择 0 个'), findsOneWidget);

    await tester.tap(find.text('实例一'));
    await tester.pump();
    expect(find.text('已选择 1 个'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();
    expect(find.text('已选择 2 个'), findsOneWidget);

    await tester.tap(find.byTooltip('删除选中的实例'));
    await tester.pumpAndSettle();
    expect(find.text('删除选中实例'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(store.profiles, isEmpty);
    expect(find.text('还没有 OlivOS 实例'), findsOneWidget);
  });
}
