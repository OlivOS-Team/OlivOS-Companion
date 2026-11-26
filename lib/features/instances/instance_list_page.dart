import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/url_utils.dart';
import '../../models/instance_profile.dart';
import '../../state/instances_provider.dart';
import '../webview/instance_webview_page.dart';

class InstanceListPage extends ConsumerWidget {
  const InstanceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instances = ref.watch(instancesProvider);
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
      ),
      body: instances.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _PageMessage(message: '读取实例失败：$error'),
        data: (items) => _InstanceListBody(
          items: items,
          onAdd: () => _showAddDialog(context),
          onOpen: (profile) => _openInstance(context, ref, profile),
          onDelete: (profile) => _confirmDelete(context, ref, profile),
        ),
      ),
    );
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

class _InstanceListBody extends StatelessWidget {
  const _InstanceListBody({
    required this.items,
    required this.onAdd,
    required this.onOpen,
    required this.onDelete,
  });

  final List<InstanceProfile> items;
  final VoidCallback onAdd;
  final ValueChanged<InstanceProfile> onOpen;
  final ValueChanged<InstanceProfile> onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader(count: items.length, onAdd: onAdd),
                const SizedBox(height: 16),
                Expanded(
                  child: items.isEmpty
                      ? _EmptyState(onAdd: onAdd)
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final profile = items[index];
                            return _InstanceCard(
                              profile: profile,
                              onOpen: () => onOpen(profile),
                              onDelete: () => onDelete(profile),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.count, required this.onAdd});

  final int count;
  final VoidCallback onAdd;

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
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('添加实例'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

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
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加实例'),
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
    required this.onDelete,
  });

  final InstanceProfile profile;
  final VoidCallback onOpen;
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
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
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
