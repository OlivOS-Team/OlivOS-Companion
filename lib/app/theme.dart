import 'package:material_ui/material_ui.dart';

/// OlivOS WebUI 的调色板，来源：`OlivOS/webUI/static/style.css`。
class OlivOSColors {
  const OlivOSColors({
    required this.background,
    required this.panel,
    required this.text,
    required this.muted,
    required this.line,
    required this.accent,
    required this.brand,
    required this.primaryBackground,
    required this.primaryHover,
    required this.primaryBorder,
    required this.hover,
    required this.selectedBackground,
    required this.selectedText,
    required this.danger,
    required this.dangerBackground,
    required this.dangerBorder,
    required this.focusRing,
    required this.shadow,
    required this.dialogShadow,
  });

  final Color background;
  final Color panel;
  final Color text;
  final Color muted;
  final Color line;
  final Color accent;
  final Color brand;
  final Color primaryBackground;
  final Color primaryHover;
  final Color primaryBorder;
  final Color hover;
  final Color selectedBackground;
  final Color selectedText;
  final Color danger;
  final Color dangerBackground;
  final Color dangerBorder;
  final Color focusRing;
  final Color shadow;
  final Color dialogShadow;

  static const light = OlivOSColors(
    background: Color(0xFFF5F6F8),
    panel: Color(0xFFFFFFFF),
    text: Color(0xFF20252B),
    muted: Color(0xFF626B75),
    line: Color(0xFFDCE1E6),
    accent: Color(0xFF00A0EA),
    brand: Color(0xFF006C98),
    primaryBackground: Color(0xFFEDF7FC),
    primaryHover: Color(0xFFDFEFF7),
    primaryBorder: Color(0xFFA6D8EF),
    hover: Color(0xFFE6F3F9),
    selectedBackground: Color(0xFFE6F3F9),
    selectedText: Color(0xFF006C98),
    danger: Color(0xFFB82C35),
    dangerBackground: Color(0xFFFDEEEE),
    dangerBorder: Color(0xFFF0B6BB),
    focusRing: Color(0x4700A0EA),
    shadow: Color(0x0A182330),
    dialogShadow: Color(0x1F182330),
  );

  static const dark = OlivOSColors(
    background: Color(0xFF191B1F),
    panel: Color(0xFF22252A),
    text: Color(0xFFEAEDF0),
    muted: Color(0xFFAAB1BA),
    line: Color(0xFF3B4047),
    accent: Color(0xFF00A0EA),
    brand: Color(0xFF63CFFF),
    primaryBackground: Color(0xFF183442),
    primaryHover: Color(0xFF214657),
    primaryBorder: Color(0xFF356078),
    hover: Color(0xFF2B3940),
    selectedBackground: Color(0xFF004A66),
    selectedText: Color(0xFFEFFAFF),
    danger: Color(0xFFFF9296),
    dangerBackground: Color(0xFF3A2023),
    dangerBorder: Color(0xFF81444A),
    focusRing: Color(0x4763CFFF),
    shadow: Color(0x22000000),
    dialogShadow: Color(0x55000000),
  );
}

ThemeData buildOlivOSTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark
      ? OlivOSColors.dark
      : OlivOSColors.light;
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: colors.accent,
        brightness: brightness,
      ).copyWith(
        primary: colors.brand,
        onPrimary: brightness == Brightness.dark
            ? const Color(0xFF00212E)
            : Colors.white,
        primaryContainer: colors.primaryBackground,
        onPrimaryContainer: colors.brand,
        secondary: colors.accent,
        onSecondary: Colors.white,
        secondaryContainer: colors.hover,
        onSecondaryContainer: colors.selectedText,
        surface: colors.panel,
        onSurface: colors.text,
        surfaceContainerHighest: colors.background,
        onSurfaceVariant: colors.muted,
        outline: colors.line,
        outlineVariant: colors.line,
        error: colors.danger,
        onError: Colors.white,
        errorContainer: colors.dangerBackground,
        onErrorContainer: colors.danger,
        surfaceTint: Colors.transparent,
      );

  final textTheme = TextTheme(
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: colors.text,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: colors.text,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: colors.text,
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: colors.text,
    ),
    bodyLarge: TextStyle(fontSize: 15, height: 1.6, color: colors.text),
    bodyMedium: TextStyle(fontSize: 15, height: 1.6, color: colors.text),
    bodySmall: TextStyle(fontSize: 13, height: 1.5, color: colors.muted),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: colors.text,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: colors.text,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: colors.muted,
    ),
  );

  final controlRadius = BorderRadius.circular(8);
  final controlShape = RoundedRectangleBorder(borderRadius: controlRadius);
  final controlPadding = const EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 7,
  );

  OutlineInputBorder inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: controlRadius,
      borderSide: BorderSide(color: color),
    );
  }

  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colors.background,
    canvasColor: colors.panel,
    cardColor: colors.panel,
    dividerColor: colors.line,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    visualDensity: VisualDensity.standard,
    splashFactory: NoSplash.splashFactory,
    iconTheme: IconThemeData(color: colors.muted, size: 20),
    primaryIconTheme: IconThemeData(color: colors.brand, size: 20),
    appBarTheme: AppBarThemeData(
      backgroundColor: colors.panel,
      foregroundColor: colors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      toolbarHeight: 64,
      titleSpacing: 24,
      shape: Border(bottom: BorderSide(color: colors.line)),
      iconTheme: IconThemeData(color: colors.muted),
      actionsIconTheme: IconThemeData(color: colors.muted),
      titleTextStyle: textTheme.titleMedium,
    ),
    cardTheme: CardThemeData(
      color: colors.panel,
      surfaceTintColor: Colors.transparent,
      shadowColor: colors.shadow,
      elevation: 1,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: colors.line),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.panel,
      surfaceTintColor: Colors.transparent,
      shadowColor: colors.dialogShadow,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.line),
      ),
      titleTextStyle: textTheme.titleMedium,
      contentTextStyle: textTheme.bodyMedium,
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      insetPadding: const EdgeInsets.all(20),
      barrierColor: const Color(0x66000000),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: colors.panel,
      isDense: true,
      constraints: const BoxConstraints(minHeight: 36),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: inputBorder(colors.line),
      enabledBorder: inputBorder(colors.line),
      focusedBorder: inputBorder(colors.accent),
      errorBorder: inputBorder(colors.danger),
      focusedErrorBorder: inputBorder(colors.danger),
      disabledBorder: inputBorder(colors.line.withValues(alpha: 0.6)),
      labelStyle: textTheme.bodySmall?.copyWith(color: colors.muted),
      floatingLabelStyle: textTheme.bodySmall?.copyWith(color: colors.brand),
      hintStyle: textTheme.bodyMedium?.copyWith(color: colors.muted),
      helperStyle: textTheme.bodySmall?.copyWith(color: colors.muted),
      errorStyle: textTheme.bodySmall?.copyWith(color: colors.danger),
      prefixIconColor: colors.muted,
      suffixIconColor: colors.muted,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(0, 36)),
        padding: WidgetStateProperty.all(controlPadding),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: WidgetStateProperty.all(controlShape),
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.primaryBackground.withValues(alpha: 0.55);
          }
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered)) {
            return colors.primaryHover;
          }
          return colors.primaryBackground;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.brand.withValues(alpha: 0.55);
          }
          return colors.brand;
        }),
        side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
          final active =
              states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered);
          return BorderSide(
            color: active ? colors.accent : colors.primaryBorder,
          );
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(0, 36)),
        padding: WidgetStateProperty.all(controlPadding),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: WidgetStateProperty.all(controlShape),
        foregroundColor: WidgetStateProperty.all(colors.text),
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return colors.hover;
          }
          return colors.panel;
        }),
        side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
          final active =
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed);
          return BorderSide(color: active ? colors.accent : colors.line);
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(0, 36)),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: WidgetStateProperty.all(controlShape),
        foregroundColor: WidgetStateProperty.all(colors.text),
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return colors.hover;
          }
          return null;
        }),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return colors.text;
          }
          return colors.muted;
        }),
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return colors.hover;
          }
          return null;
        }),
        shape: WidgetStateProperty.all(controlShape),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        return states.contains(WidgetState.selected)
            ? Colors.white
            : colors.muted;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        return states.contains(WidgetState.selected)
            ? colors.accent
            : colors.line;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.text,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: colors.panel),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: controlRadius),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.accent,
      linearTrackColor: colors.line,
      circularTrackColor: colors.line,
    ),
    dividerTheme: DividerThemeData(color: colors.line, thickness: 1, space: 1),
    popupMenuTheme: PopupMenuThemeData(
      color: brightness == Brightness.dark
          ? const Color(0xFF24282E)
          : colors.panel,
      surfaceTintColor: Colors.transparent,
      shadowColor: colors.dialogShadow,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: controlRadius,
        side: BorderSide(color: colors.line),
      ),
      textStyle: textTheme.bodyMedium,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      iconColor: colors.muted,
      textColor: colors.text,
      titleTextStyle: textTheme.titleSmall,
      subtitleTextStyle: textTheme.bodySmall,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colors.text,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: textTheme.labelSmall?.copyWith(color: colors.panel),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.brand,
      selectionColor: colors.focusRing,
      selectionHandleColor: colors.brand,
    ),
  );
}
