import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/url_utils.dart';
import '../../data/config_transfer.dart';
import '../../l10n/app_error_localizations.dart';
import '../../l10n/app_localizations.dart';
import '../../models/app_language.dart';
import '../../models/instance_profile.dart';
import '../../state/instances_provider.dart';
import '../../state/language_mode_provider.dart';
import '../../state/theme_mode_provider.dart';
import '../../widgets/app_menu.dart';
import '../about/about_dialog.dart';
import '../qr/qr_code_dialog.dart';
import '../qr/qr_image_decoder.dart';
import '../qr/qr_scanner_page.dart';
import '../webview/instance_webview_page.dart';

bool get _supportsQrScanning =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

class InstanceListPage extends ConsumerStatefulWidget {
  const InstanceListPage({super.key});

  @override
  ConsumerState<InstanceListPage> createState() => _InstanceListPageState();
}

class _InstanceListPageState extends ConsumerState<InstanceListPage> {
  bool _batchMode = false;
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final instances = ref.watch(instancesProvider);
    final appLanguage = ref.watch(appLanguageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 72,
        titleSpacing: 12,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24, top: 12, bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/branding/olivos.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OlivOS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              'Witness Union / 见证联合',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? l10n.switchToLightMode : l10n.switchToDarkMode,
            onPressed: () => ref
                .read(themeModeProvider.notifier)
                .toggle(Theme.of(context).brightness),
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppMenuIconButton(
              buttonKey: const Key('more-menu'),
              tooltip: l10n.more,
              icon: Icons.more_vert,
              alignmentOffset: const Offset(48 - AppMenu.width, 0),
              menuChildren: [
                AppMenuSubmenuButton(
                  key: const Key('language-submenu'),
                  icon: Icons.translate,
                  label: l10n.language,
                  menuChildren: [
                    AppMenuItemButton(
                      key: const Key('language-system'),
                      icon: null,
                      label: l10n.followSystemLanguage,
                      checked: appLanguage == AppLanguage.system,
                      onPressed: () => ref
                          .read(appLanguageProvider.notifier)
                          .setLanguage(AppLanguage.system),
                    ),
                    AppMenuItemButton(
                      key: const Key('language-chinese'),
                      icon: null,
                      label: l10n.simplifiedChinese,
                      checked: appLanguage == AppLanguage.chinese,
                      onPressed: () => ref
                          .read(appLanguageProvider.notifier)
                          .setLanguage(AppLanguage.chinese),
                    ),
                    AppMenuItemButton(
                      key: const Key('language-english'),
                      icon: null,
                      label: l10n.english,
                      checked: appLanguage == AppLanguage.english,
                      onPressed: () => ref
                          .read(appLanguageProvider.notifier)
                          .setLanguage(AppLanguage.english),
                    ),
                  ],
                ),
                AppMenu.divider(context),
                AppMenuItemButton(
                  icon: Icons.info_outline,
                  label: l10n.about,
                  onPressed: () => showOlivOSCompanionAboutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
      body: instances.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _PageMessage(message: l10n.instancesLoadFailed('$error')),
        data: (items) => _InstanceListBody(
          items: items,
          batchMode: _batchMode,
          selectedIds: _selectedIds,
          onToggleBatchMode: _toggleBatchMode,
          onToggleSelected: _toggleSelected,
          onDeleteSelected: () => _deleteSelected(context, ref),
          onAdd: () => _showAddDialog(context),
          onImport: () => _importFromClipboard(context, ref),
          onPickQrImage: () => _importQrFromGallery(context, ref),
          onScanQr: _supportsQrScanning ? () => _scanQr(context, ref) : null,
          onExportAll: () => _exportAll(context, ref),
          onExportAllQr: () => _exportAllQr(context, ref),
          onOpen: (profile) => _openInstance(context, ref, profile),
          onEdit: (profile) => _showEditDialog(context, ref, profile),
          onExport: (profile) => _exportSingle(context, ref, profile),
          onExportQr: (profile) => _exportSingleQr(context, ref, profile),
          onDelete: (profile) => _confirmDelete(context, ref, profile),
        ),
      ),
    );
  }

  void _toggleBatchMode() {
    setState(() {
      _batchMode = !_batchMode;
      if (!_batchMode) _selectedIds.clear();
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (!_selectedIds.add(id)) _selectedIds.remove(id);
    });
  }

  List<InstanceProfile> _selectedProfiles(WidgetRef ref) {
    final profiles = ref.read(instancesProvider).value ?? const [];
    return profiles
        .where((profile) => _selectedIds.contains(profile.id))
        .toList();
  }

  Future<void> _deleteSelected(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final profiles = _selectedProfiles(ref);
    if (profiles.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.selectInstancesToDelete)));
      return;
    }

    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSelectedInstancesTitle),
        content: Text(l10n.deleteSelectedConfirm(profiles.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error.withValues(alpha: 0.35)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(instancesProvider.notifier)
          .removeProfiles(profiles.map((profile) => profile.id));
      if (!context.mounted) return;
      setState(() {
        _selectedIds.clear();
        _batchMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deletedInstances(profiles.length))),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.deleteFailed('$error'))));
    }
  }

  Future<List<InstanceConfigEntry>> _configEntries(
    WidgetRef ref,
    List<InstanceProfile> profiles,
  ) async {
    final store = ref.read(instanceStoreProvider);
    final entries = <InstanceConfigEntry>[];
    for (final profile in profiles) {
      entries.add(
        InstanceConfigEntry(
          name: profile.name,
          baseUrl: profile.baseUrl,
          autoLogin: profile.autoLogin,
          password: await store.readPassword(profile.id),
        ),
      );
    }
    return entries;
  }

  Future<void> _copyConfig(
    BuildContext context,
    List<InstanceConfigEntry> entries,
    String message,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await Clipboard.setData(
        ClipboardData(text: ConfigTransfer.encode(entries)),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.exportFailed('$error'))));
    }
  }

  Future<void> _exportAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final profiles = _batchMode
        ? _selectedProfiles(ref)
        : ref.read(instancesProvider).value ?? const [];
    if (profiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _batchMode
                ? l10n.selectInstancesToExport
                : l10n.noInstancesToExport,
          ),
        ),
      );
      return;
    }

    try {
      final entries = await _configEntries(ref, profiles);
      if (!context.mounted) return;
      await _copyConfig(
        context,
        entries,
        _batchMode
            ? l10n.exportedSelectedToClipboard(entries.length)
            : l10n.exportedAllToClipboard(entries.length),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.exportFailed('$error'))));
    }
  }

  Future<void> _exportSingle(
    BuildContext context,
    WidgetRef ref,
    InstanceProfile profile,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      final entries = await _configEntries(ref, [profile]);
      if (!context.mounted) return;
      await _copyConfig(
        context,
        entries,
        l10n.exportedInstanceToClipboard(profile.name),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.exportFailed('$error'))));
    }
  }

  Future<void> _exportAllQr(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final profiles = _batchMode
        ? _selectedProfiles(ref)
        : ref.read(instancesProvider).value ?? const [];
    if (profiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _batchMode
                ? l10n.selectInstancesToExport
                : l10n.noInstancesToExport,
          ),
        ),
      );
      return;
    }

    try {
      final entries = await _configEntries(ref, profiles);
      if (!context.mounted) return;
      await showConfigQrDialog(
        context,
        data: ConfigTransfer.encode(entries),
        description: _batchMode
            ? l10n.selectedInstancesQrDescription(entries.length)
            : l10n.allInstancesQrDescription(entries.length),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.qrGenerateFailed('$error'))));
    }
  }

  Future<void> _exportSingleQr(
    BuildContext context,
    WidgetRef ref,
    InstanceProfile profile,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      final entries = await _configEntries(ref, [profile]);
      if (!context.mounted) return;
      await showConfigQrDialog(
        context,
        data: ConfigTransfer.encode(entries),
        description: l10n.instanceQrDescription(profile.name),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.qrGenerateFailed('$error'))));
    }
  }

  Future<void> _importFromClipboard(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    ClipboardData? data;
    try {
      data = await Clipboard.getData(Clipboard.kTextPlain);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.readClipboardFailed('$error'))),
      );
      return;
    }

    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.clipboardEmpty)));
      return;
    }

    if (!context.mounted) return;
    await _importConfigText(context, ref, text);
  }

  Future<void> _importQrFromGallery(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final XFile? image;
    try {
      image = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.selectImageFailed('$error'))));
      return;
    }
    if (image == null || !context.mounted) return;

    String? text;
    try {
      text = await decodeQrCodeFromImage(image.path);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.recognizeQrFailed('$error'))));
      return;
    }
    if (!context.mounted) return;
    if (text == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.noQrInImage)));
      return;
    }
    await _importConfigText(
      context,
      ref,
      text,
      title: l10n.importQrConfigTitle,
    );
  }

  Future<void> _scanQr(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final text = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => const QrScannerPage(),
      ),
    );
    if (text == null || !context.mounted) return;
    await _importConfigText(
      context,
      ref,
      text,
      title: l10n.importQrConfigTitle,
    );
  }

  Future<void> _importConfigText(
    BuildContext context,
    WidgetRef ref,
    String text, {
    String? title,
  }) async {
    final l10n = AppLocalizations.of(context);
    List<InstanceConfigEntry> entries;
    try {
      entries = ConfigTransfer.decode(text);
    } on ConfigTransferException catch (error) {
      if (!context.mounted) return;
      final detail = l10n.configTransferFailureMessage(
        error.failure,
        detail: error.detail,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.importFailed(detail))));
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? l10n.importFromClipboardTitle),
        content: Text(l10n.importConfirm(entries.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.importAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final count = await ref
          .read(instancesProvider.notifier)
          .importConfig(entries);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.importedInstances(count))));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.importFailed('$error'))));
    }
  }

  Future<void> _showAddDialog(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => const InstanceEditorDialog(),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    InstanceProfile profile,
  ) async {
    var hasStoredPassword = false;
    try {
      final password = await ref
          .read(instanceStoreProvider)
          .readPassword(profile.id);
      hasStoredPassword = password != null && password.isNotEmpty;
    } catch (_) {
      // Editing can continue even if the secure store cannot be read.
    }
    if (!context.mounted) return;
    await showDialog<bool>(
      context: context,
      builder: (_) => InstanceEditorDialog(
        profile: profile,
        hasStoredPassword: hasStoredPassword,
      ),
    );
  }

  Future<void> _openInstance(
    BuildContext context,
    WidgetRef ref,
    InstanceProfile profile,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => InstanceWebViewPage(profile: profile)),
    );
    if (context.mounted) ref.invalidate(instancesProvider);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    InstanceProfile profile,
  ) async {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteInstanceTitle),
        content: Text(l10n.deleteInstanceConfirm(profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error.withValues(alpha: 0.35)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(instancesProvider.notifier).removeProfile(profile.id);
    }
  }
}

class _InstanceListBody extends StatefulWidget {
  const _InstanceListBody({
    required this.items,
    required this.batchMode,
    required this.selectedIds,
    required this.onToggleBatchMode,
    required this.onToggleSelected,
    required this.onDeleteSelected,
    required this.onAdd,
    required this.onImport,
    required this.onPickQrImage,
    required this.onScanQr,
    required this.onExportAll,
    required this.onExportAllQr,
    required this.onOpen,
    required this.onEdit,
    required this.onExport,
    required this.onExportQr,
    required this.onDelete,
  });

  final List<InstanceProfile> items;
  final bool batchMode;
  final Set<String> selectedIds;
  final VoidCallback onToggleBatchMode;
  final ValueChanged<String> onToggleSelected;
  final VoidCallback onDeleteSelected;
  final VoidCallback onAdd;
  final VoidCallback onImport;
  final VoidCallback onPickQrImage;
  final VoidCallback? onScanQr;
  final VoidCallback onExportAll;
  final VoidCallback onExportAllQr;
  final ValueChanged<InstanceProfile> onOpen;
  final ValueChanged<InstanceProfile> onEdit;
  final ValueChanged<InstanceProfile> onExport;
  final ValueChanged<InstanceProfile> onExportQr;
  final ValueChanged<InstanceProfile> onDelete;

  @override
  State<_InstanceListBody> createState() => _InstanceListBodyState();
}

class _InstanceListBodyState extends State<_InstanceListBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _contentFrame({required Widget child, required EdgeInsets padding}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fadeColor = Theme.of(context).scaffoldBackgroundColor;
    final selectedCount = widget.items
        .where((profile) => widget.selectedIds.contains(profile.id))
        .length;
    return SafeArea(
      top: false,
      child: Column(
        children: [
          _contentFrame(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _SectionHeader(
              count: widget.items.length,
              batchMode: widget.batchMode,
              selectedCount: selectedCount,
              onToggleBatchMode: widget.onToggleBatchMode,
              onDeleteSelected: widget.onDeleteSelected,
              onAdd: widget.onAdd,
              onImport: widget.onImport,
              onPickQrImage: widget.onPickQrImage,
              onScanQr: widget.onScanQr,
              onExportAll: widget.onExportAll,
              onExportAllQr: widget.onExportAllQr,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: widget.items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: _EmptyState(
                      onAdd: widget.onAdd,
                      onImport: widget.onImport,
                      onPickQrImage: widget.onPickQrImage,
                      onScanQr: widget.onScanQr,
                    ),
                  )
                : Scrollbar(
                    controller: _scrollController,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context)
                          .copyWith(scrollbars: false),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 24,
                              ),
                              itemCount: widget.items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final profile = widget.items[index];
                                return _contentFrame(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: _InstanceCard(
                                    profile: profile,
                                    batchMode: widget.batchMode,
                                    selected: widget.selectedIds.contains(
                                      profile.id,
                                    ),
                                    onToggleSelected: () =>
                                        widget.onToggleSelected(profile.id),
                                    onOpen: () => widget.onOpen(profile),
                                    onEdit: () => widget.onEdit(profile),
                                    onExport: () => widget.onExport(profile),
                                    onExportQr: () =>
                                        widget.onExportQr(profile),
                                    onDelete: () => widget.onDelete(profile),
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      fadeColor,
                                      fadeColor.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                                child: const SizedBox(height: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.count,
    required this.batchMode,
    required this.selectedCount,
    required this.onToggleBatchMode,
    required this.onDeleteSelected,
    required this.onAdd,
    required this.onImport,
    required this.onPickQrImage,
    required this.onScanQr,
    required this.onExportAll,
    required this.onExportAllQr,
  });

  final int count;
  final bool batchMode;
  final int selectedCount;
  final VoidCallback onToggleBatchMode;
  final VoidCallback onDeleteSelected;
  final VoidCallback onAdd;
  final VoidCallback onImport;
  final VoidCallback onPickQrImage;
  final VoidCallback? onScanQr;
  final VoidCallback onExportAll;
  final VoidCallback onExportAllQr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                batchMode
                    ? l10n.selectedCount(selectedCount)
                    : (count == 0
                          ? l10n.noInstancesYet
                          : l10n.instanceCount(count)),
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                batchMode ? l10n.batchMode : l10n.instancesTitle,
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (count > 0 || batchMode) ...[
          _ToolbarButton(
            tooltip: batchMode ? l10n.exitBatchMode : l10n.selectMultiple,
            icon: batchMode ? Icons.close : Icons.checklist,
            onPressed: onToggleBatchMode,
            foreground: scheme.onSurface,
            background: scheme.surfaceContainerHighest,
            borderColor: scheme.outline,
          ),
          const SizedBox(width: 6),
        ],
        _SplitMenuButton(
          enabled: !batchMode || selectedCount > 0,
          label: l10n.exportLabel,
          icon: Icons.file_upload_outlined,
          tooltip: l10n.exportOptions,
          onPressed: onExportAll,
          menuChildren: [
            AppMenuItemButton(
              icon: Icons.content_copy,
              label: l10n.exportToClipboard,
              onPressed: onExportAll,
            ),
            AppMenuItemButton(
              icon: Icons.qr_code_2,
              label: l10n.exportAsQrCode,
              onPressed: onExportAllQr,
            ),
          ],
        ),
        const SizedBox(width: 8),
        if (batchMode)
          _ToolbarButton(
            tooltip: l10n.deleteSelectedInstances,
            icon: Icons.delete_outline,
            enabled: selectedCount > 0,
            onPressed: onDeleteSelected,
            foreground: scheme.error,
            background: scheme.errorContainer,
            borderColor: scheme.error.withValues(alpha: 0.35),
          )
        else
          _ImportSplitMenuButton(
            primary: true,
            label: l10n.addLabel,
            icon: Icons.add,
            tooltip: l10n.addOptions,
            onPressed: onAdd,
            onAdd: onAdd,
            onImport: onImport,
            onPickQrImage: onPickQrImage,
            onScanQr: onScanQr,
          ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.foreground,
    required this.background,
    required this.borderColor,
    this.enabled = true,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color foreground;
  final Color background;
  final Color borderColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveForeground = enabled
        ? foreground
        : foreground.withValues(alpha: 0.38);
    final effectiveBackground = enabled
        ? background
        : background.withValues(alpha: 0.5);
    final effectiveBorder = enabled
        ? borderColor
        : borderColor.withValues(alpha: 0.5);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: effectiveBackground,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: effectiveBorder),
        ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Icon(icon, size: 18, color: effectiveForeground),
          ),
        ),
      ),
    );
  }
}

class _ImportSplitMenuButton extends StatelessWidget {
  const _ImportSplitMenuButton({
    required this.label,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.onAdd,
    required this.onImport,
    required this.onPickQrImage,
    required this.onScanQr,
    this.primary = false,
    this.showLabel = false,
    this.includeManualAdd = true,
  });

  final String label;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final VoidCallback onAdd;
  final VoidCallback onImport;
  final VoidCallback onPickQrImage;
  final VoidCallback? onScanQr;
  final bool primary;
  final bool showLabel;
  final bool includeManualAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SplitMenuButton(
      primary: primary,
      showLabel: showLabel,
      label: label,
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      menuChildren: [
        if (includeManualAdd)
          AppMenuItemButton(
            icon: Icons.add,
            label: l10n.addManually,
            onPressed: onAdd,
          ),
        AppMenuItemButton(
          icon: Icons.content_paste_go,
          label: l10n.importFromClipboard,
          onPressed: onImport,
        ),
        AppMenuItemButton(
          icon: Icons.photo_library_outlined,
          label: l10n.chooseFromGallery,
          onPressed: onPickQrImage,
        ),
        if (onScanQr != null)
          AppMenuItemButton(
            icon: Icons.qr_code_scanner,
            label: l10n.scanQrCode,
            onPressed: onScanQr!,
          ),
      ],
    );
  }
}

class _SplitMenuButton extends StatelessWidget {
  const _SplitMenuButton({
    required this.label,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.menuChildren,
    this.primary = false,
    this.enabled = true,
    this.showLabel = false,
  });

  final String label;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final List<Widget> menuChildren;
  final bool primary;
  final bool enabled;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : primary
        ? scheme.onPrimary
        : scheme.onSurface;
    final background = !enabled
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : primary
        ? scheme.primary
        : scheme.surfaceContainerHighest;
    final borderColor = !enabled
        ? scheme.outline.withValues(alpha: 0.5)
        : primary
        ? scheme.primary
        : scheme.outline;
    final dividerColor = !enabled
        ? scheme.outline.withValues(alpha: 0.5)
        : primary
        ? scheme.onPrimary.withValues(alpha: 0.35)
        : scheme.outline;

    return Material(
      color: background,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: label,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              child: Padding(
                padding: showLabel
                    ? const EdgeInsets.fromLTRB(12, 8, 10, 8)
                    : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: showLabel
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 18, color: foreground),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: foreground,
                            ),
                          ),
                        ],
                      )
                    : Icon(icon, size: 18, color: foreground),
              ),
            ),
          ),
          Container(width: 1, height: 18, color: dividerColor),
          AppMenuAnchor(
            alignmentOffset: const Offset(34 - AppMenu.width, 0),
            menuChildren: menuChildren,
            builder: (context, controller, child) => Tooltip(
              message: tooltip,
              child: InkWell(
                onTap: enabled
                    ? () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 9,
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onAdd,
    required this.onImport,
    required this.onPickQrImage,
    required this.onScanQr,
  });

  final VoidCallback onAdd;
  final VoidCallback onImport;
  final VoidCallback onPickQrImage;
  final VoidCallback? onScanQr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/branding/olivos.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.noInstancesMessage,
                  style: textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.noInstancesDescription,
                  style: textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.addInstance),
                    ),
                    _ImportSplitMenuButton(
                      showLabel: true,
                      includeManualAdd: false,
                      label: l10n.importFromClipboard,
                      icon: Icons.content_paste_go,
                      tooltip: l10n.importOptions,
                      onPressed: onImport,
                      onAdd: onAdd,
                      onImport: onImport,
                      onPickQrImage: onPickQrImage,
                      onScanQr: onScanQr,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InstanceCard extends StatelessWidget {
  const _InstanceCard({
    required this.profile,
    required this.batchMode,
    required this.selected,
    required this.onToggleSelected,
    required this.onOpen,
    required this.onEdit,
    required this.onExport,
    required this.onExportQr,
    required this.onDelete,
  });

  final InstanceProfile profile;
  final bool batchMode;
  final bool selected;
  final VoidCallback onToggleSelected;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onExport;
  final VoidCallback onExportQr;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const anchorWidth = 48.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected ? scheme.primaryContainer.withValues(alpha: 0.75) : null,
      shape: selected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: scheme.primary),
            )
          : null,
      child: InkWell(
        onTap: batchMode ? onToggleSelected : onOpen,
        hoverColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/branding/olivos.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.baseUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (profile.autoLogin) ...[
                      const SizedBox(height: 6),
                      _Tag(label: l10n.autoLoginTag),
                    ],
                  ],
                ),
              ),
              if (batchMode)
                Checkbox(value: selected, onChanged: (_) => onToggleSelected())
              else
                AppMenuIconButton(
                  icon: Icons.more_vert,
                  tooltip: l10n.moreActions,
                  alignmentOffset: const Offset(anchorWidth - AppMenu.width, 0),
                  menuChildren: [
                    AppMenuItemButton(
                      icon: Icons.edit_outlined,
                      label: l10n.editAction,
                      onPressed: onEdit,
                    ),
                    AppMenuSubmenuButton(
                      icon: Icons.file_upload_outlined,
                      label: l10n.exportLabel,
                      menuChildren: [
                        AppMenuItemButton(
                          icon: Icons.content_copy,
                          label: l10n.exportToClipboard,
                          onPressed: onExport,
                        ),
                        AppMenuItemButton(
                          icon: Icons.qr_code_2,
                          label: l10n.exportAsQrCode,
                          onPressed: onExportQr,
                        ),
                      ],
                    ),
                    AppMenu.divider(context),
                    AppMenuItemButton(
                      icon: Icons.delete_outline,
                      label: l10n.delete,
                      onPressed: onDelete,
                      color: scheme.error,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: scheme.primary, fontSize: 11),
      ),
    );
  }
}

class _PageMessage extends StatelessWidget {
  const _PageMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class InstanceEditorDialog extends ConsumerStatefulWidget {
  const InstanceEditorDialog({
    super.key,
    this.profile,
    this.hasStoredPassword = false,
  });

  final InstanceProfile? profile;
  final bool hasStoredPassword;

  bool get isEditing => profile != null;

  @override
  ConsumerState<InstanceEditorDialog> createState() =>
      _InstanceEditorDialogState();
}

class _InstanceEditorDialogState extends ConsumerState<InstanceEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _passwordController;

  late bool _autoLogin;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _urlController = TextEditingController(text: profile?.baseUrl ?? '');
    _passwordController = TextEditingController();
    _autoLogin = profile?.autoLogin ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final baseUrl = normalizeBaseUrl(_urlController.text);
    if (baseUrl == null) {
      setState(() => _error = l10n.invalidUrlError);
      return;
    }
    final password = _passwordController.text;
    if (_autoLogin && password.isEmpty && !widget.hasStoredPassword) {
      setState(() => _error = l10n.autoLoginPasswordRequiredError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final name = _nameController.text.trim().isEmpty
          ? Uri.parse(baseUrl).host
          : _nameController.text.trim();
      final notifier = ref.read(instancesProvider.notifier);
      final newPassword = password.isEmpty ? null : password;
      final profile = widget.profile;
      if (profile != null) {
        await notifier.updateProfile(
          id: profile.id,
          name: name,
          baseUrl: baseUrl,
          autoLogin: _autoLogin,
          password: newPassword,
        );
      } else {
        await notifier.addProfile(
          name: name,
          baseUrl: baseUrl,
          autoLogin: _autoLogin,
          password: newPassword,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l10n.saveFailed('$error');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AlertDialog(
      title: Text(
        widget.isEditing ? l10n.editInstanceTitle : l10n.addInstanceTitle,
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isEditing
                    ? l10n.editInstanceDescription
                    : l10n.addInstanceDescription,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.nameOptionalLabel,
                  hintText: l10n.nameHint,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: l10n.webUiAddressLabel,
                  hintText: 'http://192.168.1.10:20480',
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.webUiPasswordLabel,
                  helperText: widget.isEditing && widget.hasStoredPassword
                      ? l10n.passwordKeepCurrentHelper
                      : l10n.passwordSecureHelper,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.autoLoginTitle),
                subtitle: Text(l10n.autoLoginSubtitle),
                value: _autoLogin,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _autoLogin = value),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 16, color: scheme.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isEditing ? l10n.save : l10n.add),
        ),
      ],
    );
  }
}
