import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const Key('component-licenses-page'),
      appBar: AppBar(title: Text(l10n.componentLicensesTitle)),
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
                  final subtitle = entry.subtitle(l10n);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(entry.name),
                      subtitle: subtitle == null ? null : Text(subtitle),
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

  String? subtitle(AppLocalizations l10n) {
    final lockedVersion = version;
    if (lockedVersion == null) return null;
    return l10n.componentVersion(
      lockedVersion.version,
      isDevDependency: lockedVersion.isDevDependency,
    );
  }
}

class _ComponentLicensePage extends StatelessWidget {
  const _ComponentLicensePage({required this.entry});

  final _ComponentEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final subtitle = entry.subtitle(l10n);
    return Scaffold(
      appBar: AppBar(title: Text(entry.name)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (subtitle != null) ...[
                Text(subtitle, style: textTheme.bodyMedium),
                const SizedBox(height: 16),
              ],
              if (entry.licenses.isEmpty)
                Text(l10n.componentLicenseMissing)
              else ...[
                Text(
                  l10n.componentLicenseTextTitle,
                  style: textTheme.titleSmall,
                ),
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
        child: Text(
          AppLocalizations.of(context).componentLoadFailed('$error'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
