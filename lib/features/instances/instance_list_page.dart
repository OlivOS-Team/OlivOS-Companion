import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      appBar: AppBar(title: const Text('OlivOS Companion')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('添加实例'),
      ),
      body: instances.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('读取实例失败：$error')),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyState(onAdd: () => _showAddDialog(context));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final profile = items[index];
              return _InstanceCard(
                profile: profile,
                onOpen: () => _openInstance(context, profile),
                onDelete: () => _confirmDelete(context, ref, profile),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => const AddInstanceDialog(),
    );
  }

  void _openInstance(BuildContext context, InstanceProfile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => InstanceWebViewPage(profile: profile)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    InstanceProfile profile,
  ) async {
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dns_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '还没有 OlivOS 实例',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '添加一个 WebUI 地址，之后可以在这里快速切换多个实例。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('添加实例'),
            ),
          ],
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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onOpen,
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: const Icon(Icons.public),
        ),
        title: Text(profile.name),
        subtitle: Text(profile.baseUrl),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
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
    return AlertDialog(
      title: const Text('添加实例'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
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
