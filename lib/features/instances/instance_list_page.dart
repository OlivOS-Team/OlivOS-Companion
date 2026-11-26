import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/url_utils.dart';
import '../../data/config_transfer.dart';
import '../../models/instance_profile.dart';
import '../../state/instances_provider.dart';
import '../../state/theme_mode_provider.dart';
import '../webview/instance_webview_page.dart';

class InstanceListPage extends ConsumerWidget {
  const InstanceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instances = ref.watch(instancesProvider);
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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: isDark ? '切换到浅色模式' : '切换到深色模式',
              onPressed: () => ref
                  .read(themeModeProvider.notifier)
                  .toggle(Theme.of(context).brightness),
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
            ),
          ),
        ],
      ),
      body: instances.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _PageMessage(message: '读取实例失败：$error'),
        data: (items) => _InstanceListBody(
          items: items,
          onAdd: () => _showAddDialog(context),
          onImport: () => _importFromClipboard(context, ref),
          onExportAll: () => _exportAll(context, ref),
          onOpen: (profile) => _openInstance(context, ref, profile),
          onExport: (profile) => _exportSingle(context, ref, profile),
          onDelete: (profile) => _confirmDelete(context, ref, profile),
        ),
      ),
    );
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
    try {
      await Clipboard.setData(
        ClipboardData(text: ConfigTransfer.encode(entries)),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$message（Base64 编码，非加密）')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('导出失败：$error')));
    }
  }

  Future<void> _exportAll(BuildContext context, WidgetRef ref) async {
    final profiles = ref.read(instancesProvider).value ?? const [];
    if (profiles.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('没有可导出的实例')));
      return;
    }

    try {
      final entries = await _configEntries(ref, profiles);
      if (!context.mounted) return;
      await _copyConfig(context, entries, '已导出 ${entries.length} 个实例到剪贴板');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('导出失败：$error')));
    }
  }

  Future<void> _exportSingle(
    BuildContext context,
    WidgetRef ref,
    InstanceProfile profile,
  ) async {
    try {
      final entries = await _configEntries(ref, [profile]);
      if (!context.mounted) return;
      await _copyConfig(context, entries, '已导出「${profile.name}」到剪贴板');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('导出失败：$error')));
    }
  }

  Future<void> _importFromClipboard(BuildContext context, WidgetRef ref) async {
    ClipboardData? data;
    try {
      data = await Clipboard.getData(Clipboard.kTextPlain);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('读取剪贴板失败：$error')));
      return;
    }

    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('剪贴板中没有配置内容')));
      return;
    }

    List<InstanceConfigEntry> entries;
    try {
      entries = ConfigTransfer.decode(text);
    } on ConfigTransferException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('导入失败：${error.message}')));
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('从剪贴板导入'),
        content: Text('将导入 ${entries.length} 个实例；相同地址的实例会被更新，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('导入'),
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
          .showSnackBar(SnackBar(content: Text('已导入 $count 个实例')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('导入失败：$error')));
    }
  }

  Future<void> _showAddDialog(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => const AddInstanceDialog(),
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
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除实例'),
        content: Text('确定删除「${profile.name}」及其本地登录信息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error.withValues(alpha: 0.35)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
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
    required this.onAdd,
    required this.onImport,
    required this.onExportAll,
    required this.onOpen,
    required this.onExport,
    required this.onDelete,
  });

  final List<InstanceProfile> items;
  final VoidCallback onAdd;
  final VoidCallback onImport;
  final VoidCallback onExportAll;
  final ValueChanged<InstanceProfile> onOpen;
  final ValueChanged<InstanceProfile> onExport;
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
    return SafeArea(
      top: false,
      child: Column(
        children: [
          _contentFrame(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _SectionHeader(
              count: widget.items.length,
              onAdd: widget.onAdd,
              onImport: widget.onImport,
              onExportAll: widget.onExportAll,
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
                                    onOpen: () => widget.onOpen(profile),
                                    onExport: () => widget.onExport(profile),
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
    required this.onAdd,
    required this.onImport,
    required this.onExportAll,
  });

  final int count;
  final VoidCallback onAdd;
  final VoidCallback onImport;
  final VoidCallback onExportAll;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('实例', style: textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                count == 0 ? '尚未添加实例' : '$count 个实例',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        _SplitMenuButton(
          label: '导出',
          icon: Icons.file_upload_outlined,
          tooltip: '导出选项',
          onPressed: onExportAll,
          onSelected: (value) {
            if (value == 'export') onExportAll();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.content_copy, size: 18),
                  SizedBox(width: 8),
                  Text('导出到剪贴板'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        _SplitMenuButton(
          primary: true,
          label: '添加',
          icon: Icons.add,
          tooltip: '添加选项',
          onPressed: onAdd,
          onSelected: (value) {
            if (value == 'add') onAdd();
            if (value == 'import') onImport();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'add',
              child: Row(
                children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 8),
                  Text('手动添加'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  Icon(Icons.content_paste_go, size: 18),
                  SizedBox(width: 8),
                  Text('从剪贴板导入'),
                ],
              ),
            ),
          ],
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
    required this.onSelected,
    required this.itemBuilder,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final ValueChanged<String> onSelected;
  final List<PopupMenuEntry<String>> Function(BuildContext) itemBuilder;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = primary ? scheme.onPrimary : scheme.onSurface;
    final background = primary
        ? scheme.primary
        : scheme.surfaceContainerHighest;
    final borderColor = primary ? scheme.primary : scheme.outline;
    final dividerColor = primary
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
          InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
              child: Row(
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
              ),
            ),
          ),
          Container(width: 1, height: 18, color: dividerColor),
          PopupMenuButton<String>(
            tooltip: tooltip,
            onSelected: onSelected,
            itemBuilder: itemBuilder,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd, required this.onImport});

  final VoidCallback onAdd;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
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
                  '还没有 OlivOS 实例',
                  style: textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '添加一个 WebUI 地址，之后可以在这里快速切换多个实例。',
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
                      label: const Text('添加实例'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onImport,
                      icon: const Icon(Icons.content_paste_go, size: 18),
                      label: const Text('从剪贴板导入'),
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
    required this.onOpen,
    required this.onExport,
    required this.onDelete,
  });

  final InstanceProfile profile;
  final VoidCallback onOpen;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
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
                      _Tag(label: '自动登录'),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'export') onExport();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        const Icon(Icons.content_copy, size: 18),
                        const SizedBox(width: 8),
                        const Text('导出到剪贴板'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: scheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: scheme.error)),
                      ],
                    ),
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

class AddInstanceDialog extends ConsumerStatefulWidget {
  const AddInstanceDialog({super.key});

  @override
  ConsumerState<AddInstanceDialog> createState() => _AddInstanceDialogState();
}

class _AddInstanceDialogState extends ConsumerState<AddInstanceDialog> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _autoLogin = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final baseUrl = normalizeBaseUrl(_urlController.text);
    if (baseUrl == null) {
      setState(() => _error = '请输入有效地址，例如 http://192.168.1.10:20480');
      return;
    }
    final password = _passwordController.text;
    if (_autoLogin && password.isEmpty) {
      setState(() => _error = '勾选自动登录时请填写密码，或关闭自动登录');
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
      await ref
          .read(instancesProvider.notifier)
          .addProfile(
            name: name,
            baseUrl: baseUrl,
            autoLogin: _autoLogin,
            password: password,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '保存失败：$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AlertDialog(
      title: const Text('添加实例'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '添加一个 OlivOS WebUI 实例；自动登录会把密码保存到系统安全存储。',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '名称（可选）',
                  hintText: '例如：家里主实例',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'WebUI 地址',
                  hintText: 'http://192.168.1.10:20480',
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'WebUI 密码',
                  helperText: '自动登录时保存到系统安全存储',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('自动登录'),
                subtitle: const Text('启动时预登录并注入登录凭据'),
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
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('添加'),
        ),
      ],
    );
  }
}
