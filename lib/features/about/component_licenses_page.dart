import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'component_versions.dart';

typedef ComponentLicenseMap = Map<String, List<LicenseEntry>>;

/// Lists every locked component with its version and bundled license text.
class ComponentLicensesPage extends StatefulWidget {
  const ComponentLicensesPage({
    super.key,
    this.applicationVersion,
    this.versions,
    this.licenses,
  });

  /// Shown in the page header when opened from the About dialog.
  final String? applicationVersion;

  /// Test seams; production uses the bundled lockfile and Flutter notices.
  final Future<List<ComponentVersion>>? versions;
  final Future<ComponentLicenseMap>? licenses;

  @override
  State<ComponentLicensesPage> createState() => _ComponentLicensesPageState();
}

class _ComponentLicensesPageState extends State<ComponentLicensesPage> {
  late final Future<_ComponentCatalog> _catalog = _loadCatalog();

  Future<_ComponentCatalog> _loadCatalog() async {
    final versions = await (widget.versions ?? loadComponentVersions());
    final licenses = await (widget.licenses ?? _loadRegisteredLicenses());
    return _ComponentCatalog(versions, licenses);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('component-licenses-page'),
      appBar: AppBar(title: const Text('组件与许可证')),
      body: FutureBuilder<_ComponentCatalog>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadError(error: snapshot.error!);
          }
          final catalog = snapshot.data;
          if (catalog == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = catalog.entries;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: entries.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final version = widget.applicationVersion;
                    final title = version == null
                        ? 'OlivOS Companion'
                        : 'OlivOS Companion $version';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    );
                  }
                  final entry = entries[index - 1];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(entry.name),
                      subtitle: entry.subtitle == null
                          ? null
                          : Text(entry.subtitle!),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                _ComponentLicensePage(entry: entry),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<ComponentLicenseMap> _loadRegisteredLicenses() async {
  final byPackage = <String, List<LicenseEntry>>{};
  await for (final entry in LicenseRegistry.licenses) {
    for (final package in entry.packages) {
      if (package.isEmpty) continue;
      byPackage.putIfAbsent(package, () => []).add(entry);
    }
  }
  return byPackage;
}

class _ComponentCatalog {
  _ComponentCatalog(
    List<ComponentVersion> versions,
    ComponentLicenseMap licenses,
  ) : entries = _merge(versions, licenses);

  final List<_ComponentEntry> entries;

  static List<_ComponentEntry> _merge(
    List<ComponentVersion> versions,
    ComponentLicenseMap licenses,
  ) {
    final versionsByName = {
      for (final version in versions) version.name: version,
    };
    final names = <String>{...versionsByName.keys, ...licenses.keys}.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return [
      for (final name in names)
        _ComponentEntry(
          name: name,
          version: versionsByName[name],
          licenses: licenses[name] ?? const [],
        ),
    ];
  }
}

class _ComponentEntry {
  const _ComponentEntry({
    required this.name,
    required this.version,
    required this.licenses,
  });

  final String name;
  final ComponentVersion? version;
  final List<LicenseEntry> licenses;

  String? get subtitle {
    final lockedVersion = version;
    if (lockedVersion == null) return null;
    final suffix = lockedVersion.isDevDependency ? ' · 开发依赖' : '';
    return '版本 ${lockedVersion.version}$suffix';
  }
}

class _ComponentLicensePage extends StatelessWidget {
  const _ComponentLicensePage({required this.entry});

  final _ComponentEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(entry.name)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (entry.subtitle != null) ...[
                Text(entry.subtitle!, style: textTheme.bodyMedium),
                const SizedBox(height: 16),
              ],
              if (entry.licenses.isEmpty)
                const Text('未找到该组件的许可证文本。')
              else ...[
                Text('许可证文本', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final license in entry.licenses) ...[
                  _LicenseText(license: license),
                  const Divider(height: 32),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LicenseText extends StatelessWidget {
  const _LicenseText({required this.license});

  final LicenseEntry license;

  @override
  Widget build(BuildContext context) {
    final buffer = StringBuffer();
    for (final paragraph in license.paragraphs) {
      if (paragraph.indent > 0) {
        buffer.write('  ' * paragraph.indent);
      }
      buffer
        ..writeln(paragraph.text)
        ..writeln();
    }
    return SelectableText(
      buffer.toString().trimRight(),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('无法加载组件信息。\n$error', textAlign: TextAlign.center),
      ),
    );
  }
}
