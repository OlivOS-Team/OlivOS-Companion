import 'package:material_ui/material_ui.dart';

Future<void> showOlivOSCompanionAboutDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _AboutDialog(),
  );
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    Widget sectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 6),
        child: Text(
          title,
          style: textTheme.labelLarge?.copyWith(color: colors.primary),
        ),
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/branding/olivos.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('关于 OlivOS Companion')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OlivOS 多实例客户端', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Text('Witness Union / 见证联合 ', style: textTheme.bodyMedium),
            sectionTitle('归属'),
            Text(
              '本项目由 OlivOS-Team 维护，是独立的 OlivOS 生态客户端，与 '
              'OlivOS 本体分开构建和发布。本项目不修改 OlivOS 源代码。'
              'OlivOS 名称、图标及相关品牌归 OlivOS 项目及其贡献者所有。',
              style: textTheme.bodyMedium,
            ),
            sectionTitle('许可证'),
            Text(
              '本项目基于 GNU Affero General Public License v3.0'
              '（AGPL-3.0）发布。',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            SelectableText(
              'https://github.com/OlivOS-Team/OlivOS-Companion',
              style: textTheme.bodySmall?.copyWith(color: colors.primary),
            ),
            const SizedBox(height: 20),
            Text('世界是属于每一个人的。要创造一个充满逻辑并尊重每一个人的世界。', style: textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              '——А. Бабуров, А. Гутнов, И. Лежава и др.'
              '《Новый элемент расселения: на пути к новому городу》. '
              'Москва: Стройиздат, A.D. 1966.',
              style: textTheme.labelSmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
