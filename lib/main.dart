import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/theme.dart';
import 'features/instances/instance_list_page.dart';

void main() {
  runApp(const ProviderScope(child: OlivOSCompanionApp()));
}

class OlivOSCompanionApp extends StatelessWidget {
  const OlivOSCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OlivOS Companion',
      debugShowCheckedModeBanner: false,
      theme: buildOlivOSTheme(Brightness.light),
      darkTheme: buildOlivOSTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const InstanceListPage(),
    );
  }
}
