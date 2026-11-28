import 'package:material_ui/material_ui.dart';

/// Shared sizing and styling for every application menu.
class AppMenu {
  const AppMenu._();

  static const double width = 168;
  static const double itemHeight = 48;
  static const double dividerHeight = 9;
  static const EdgeInsets itemPadding = EdgeInsets.symmetric(horizontal: 12);
  static const EdgeInsets menuPadding = EdgeInsets.symmetric(vertical: 8);

  static MenuStyle menuStyle(ThemeData theme, {AlignmentGeometry? alignment}) {
    final popupTheme = theme.popupMenuTheme;
    final scheme = theme.colorScheme;
    final popupShape = popupTheme.shape;
    final shape = popupShape is OutlinedBorder
        ? popupShape
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: scheme.outline),
          );
    return MenuStyle(
      alignment: alignment,
      backgroundColor: WidgetStatePropertyAll(
        popupTheme.color ?? scheme.surface,
      ),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: WidgetStatePropertyAll(
        popupTheme.shadowColor ?? scheme.shadow,
      ),
      elevation: WidgetStatePropertyAll(popupTheme.elevation ?? 6),
      padding: const WidgetStatePropertyAll(menuPadding),
      shape: WidgetStatePropertyAll(shape),
    );
  }

  static ButtonStyle itemStyle(ThemeData theme, {Color? foreground}) {
    final color = foreground ?? theme.colorScheme.onSurface;
    return MenuItemButton.styleFrom(
      foregroundColor: color,
      textStyle: theme.textTheme.labelLarge?.copyWith(color: color),
      minimumSize: const Size(width, itemHeight),
      padding: itemPadding,
    );
  }

  static Widget divider(BuildContext context) {
    return Divider(
      height: dividerHeight,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class AppMenuRow extends StatelessWidget {
  const AppMenuRow({super.key, this.icon, required this.label, this.color});

  final IconData? icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: effectiveColor),
          const SizedBox(width: 8),
        ] else
          const SizedBox(width: 26),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(color: effectiveColor),
        ),
      ],
    );
  }
}

class AppMenuHeader extends StatelessWidget {
  const AppMenuHeader({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
        ],
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
      ],
    );
  }
}

class AppMenuSectionHeader extends StatelessWidget {
  const AppMenuSectionHeader({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: SizedBox(
        height: 24,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppMenuHeader(label: label, icon: icon),
        ),
      ),
    );
  }
}

class AppMenuItemButton extends StatelessWidget {
  const AppMenuItemButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.checked = false,
  });

  final IconData? icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MenuItemButton(
      style: AppMenu.itemStyle(theme, foreground: color),
      onPressed: onPressed,
      trailingIcon: checked
          ? Icon(Icons.check, size: 18, color: theme.colorScheme.primary)
          : null,
      child: AppMenuRow(icon: icon, label: label, color: color),
    );
  }
}

class AppMenuSubmenuButton extends StatelessWidget {
  const AppMenuSubmenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.menuChildren,
  });

  final IconData icon;
  final String label;
  final List<Widget> menuChildren;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SubmenuButton(
      style: AppMenu.itemStyle(theme),
      menuStyle: AppMenu.menuStyle(theme),
      animated: true,
      submenuIcon: const WidgetStatePropertyAll<Widget?>(
        Icon(Icons.chevron_right, size: 18),
      ),
      menuChildren: menuChildren,
      child: AppMenuRow(icon: icon, label: label),
    );
  }
}

class AppMenuAnchor extends StatelessWidget {
  const AppMenuAnchor({
    super.key,
    required this.builder,
    required this.menuChildren,
    this.alignment = AlignmentDirectional.bottomStart,
    this.alignmentOffset = Offset.zero,
  });

  final Widget Function(BuildContext, MenuController, Widget?) builder;
  final List<Widget> menuChildren;
  final AlignmentGeometry alignment;
  final Offset alignmentOffset;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: AppMenu.menuStyle(Theme.of(context), alignment: alignment),
      alignmentOffset: alignmentOffset,
      animated: true,
      menuChildren: menuChildren,
      builder: builder,
    );
  }
}

class AppMenuIconButton extends StatelessWidget {
  const AppMenuIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.menuChildren,
    this.buttonKey,
    this.alignmentOffset = Offset.zero,
    this.iconColor,
    this.iconSize,
  });

  final IconData icon;
  final String tooltip;
  final List<Widget> menuChildren;
  final Key? buttonKey;
  final Offset alignmentOffset;
  final Color? iconColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return AppMenuAnchor(
      alignmentOffset: alignmentOffset,
      menuChildren: menuChildren,
      builder: (context, controller, child) => IconButton(
        key: buttonKey,
        tooltip: tooltip,
        icon: Icon(icon, color: iconColor, size: iconSize),
        onPressed: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
      ),
    );
  }
}
