import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006C98)),
        useMaterial3: true,
      ),
      home: const InstanceListPage(),
    );
  }
}
