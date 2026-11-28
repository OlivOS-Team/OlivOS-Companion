import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  static const supportedLocales = <Locale>[Locale('en'), Locale('zh', 'CN')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations.delegate is missing.');
    return localizations!;
  }

  static Locale resolveSystemLocale(List<Locale>? systemLocales) {
    for (final locale in systemLocales ?? const <Locale>[]) {
      if (locale.languageCode == 'zh') return const Locale('zh', 'CN');
      if (locale.languageCode == 'en') return const Locale('en');
    }
    return const Locale('en');
  }

  bool get _isChinese => locale.languageCode == 'zh';

  String _t(String zh, String en) => _isChinese ? zh : en;

  String _instances(int count) {
    if (_isChinese) return '$count 个实例';
    return count == 1 ? '1 instance' : '$count instances';
  }

  String _selectedInstances(int count) {
    if (_isChinese) return '选中的 $count 个实例';
    return count == 1 ? '1 selected instance' : '$count selected instances';
  }

  // Common actions.
  String get close => _t('关闭', 'Close');
  String get cancel => _t('取消', 'Cancel');
  String get delete => _t('删除', 'Delete');
  String get save => _t('保存', 'Save');
  String get add => _t('添加', 'Add');
  String get about => _t('关于', 'About');
  String get more => _t('更多', 'More');

  // Language settings.
  String get language => _t('语言', 'Language');
  String get followSystemLanguage => _t('跟随系统', 'System');
  String get simplifiedChinese => '简体中文';
  String get english => 'English';

  // Main app bar.
  String get switchToLightMode => _t('切换到浅色模式', 'Switch to light mode');
  String get switchToDarkMode => _t('切换到深色模式', 'Switch to dark mode');
  String openLinkFailed(String uri) =>
      _t('无法打开链接：$uri', 'Unable to open link: $uri');

  // About dialog.
  String get aboutTitle => _t('关于 OlivOS Companion', 'About OlivOS Companion');
  String get aboutSubtitle =>
      _t('OlivOS 多实例托盘 客户端', 'OlivOS multi-instance tray client');
  String get aboutAttributionTitle => _t('归属', 'Attribution');
  String get aboutAttributionBody => _t(
    '本项目由 OlivOS-Team 维护，是独立的 OlivOS 生态客户端，与 '
        'OlivOS 本体分开构建和发布。本项目不修改 OlivOS 源代码。'
        'OlivOS 名称、图标及相关品牌归 OlivOS 项目及其贡献者所有。',
    'This project is maintained by OlivOS-Team as an independent client '
        'in the OlivOS ecosystem, built and released separately from OlivOS '
        'itself. This project does not modify OlivOS source code. The OlivOS '
        'name, logo, and related branding belong to the OlivOS project and '
        'its contributors.',
  );
  String get aboutLicenseTitle => _t('许可证', 'License');
  String get aboutLicensePrefix => _t(
    '本项目基于 GNU Affero General Public License v3.0（',
    'This project is released under the GNU Affero General Public License '
        'v3.0 (',
  );
  String get aboutLicenseSuffix => _t('）发布。', ').');
  String get aboutMotto => _isChinese
      ? '世界是属于每一个人的。要创造一个充满逻辑并尊重每一个人的世界。'
      : 'Мир, принадлежащий всем и каждому, мир, исполненный логики '
            'и уважения к человеку.';
  String get aboutLogoLabel => _t('OlivOS 品牌图标', 'OlivOS brand logo');
  String get aboutVersionLoading => _t('版本 …', 'Version …');
  String get aboutVersionTooltip =>
      _t('查看组件版本与开源许可证', 'View component versions and open-source licenses');
  String aboutVersion(String version) => _t('版本 $version', 'Version $version');

  // Component licenses page.
  String get componentLicensesTitle => _t('组件与许可证', 'Components & Licenses');
  String componentVersion(String version, {required bool isDevDependency}) {
    final suffix = isDevDependency ? _t(' · 开发依赖', ' · dev dependency') : '';
    return _t('版本 $version$suffix', 'Version $version$suffix');
  }

  String get componentLicenseMissing =>
      _t('未找到该组件的许可证文本。', 'No license text found for this component.');
  String get componentLicenseTextTitle => _t('许可证文本', 'License text');
  String componentLoadFailed(String detail) => _t(
    '无法加载组件信息。\n$detail',
    'Unable to load component information.\n$detail',
  );

  // Instance list.
  String instancesLoadFailed(String detail) =>
      _t('读取实例失败：$detail', 'Failed to load instances: $detail');
  String get noInstancesMessage =>
      _t('还没有 OlivOS 实例', 'No OlivOS instances yet');
  String get noInstancesDescription => _t(
    '添加一个 WebUI 地址，之后可以在这里快速切换多个实例。',
    'Add a WebUI address, then quickly switch between instances here.',
  );
  String get addInstance => _t('添加实例', 'Add instance');
  String get importFromClipboard => _t('从剪贴板导入', 'Import from clipboard');
  String get importOptions => _t('导入选项', 'Import options');
  String selectedCount(int count) => _t('已选择 $count 个', '$count selected');
  String get noInstancesYet => _t('尚未添加实例', 'No instances yet');
  String instanceCount(int count) => _instances(count);
  String get batchMode => _t('批量模式', 'Batch mode');
  String get instancesTitle => _t('实例', 'Instances');
  String get exitBatchMode => _t('退出批量模式', 'Exit batch mode');
  String get selectMultiple => _t('批量选择', 'Select multiple');
  String get exportLabel => _t('导出', 'Export');
  String get exportOptions => _t('导出选项', 'Export options');
  String get exportToClipboard => _t('导出到剪贴板', 'Export to clipboard');
  String get exportAsQrCode => _t('导出为二维码', 'Export as QR code');
  String get deleteSelectedInstances =>
      _t('删除选中的实例', 'Delete selected instances');
  String get addLabel => _t('添加', 'Add');
  String get addOptions => _t('添加选项', 'Add options');
  String get addManually => _t('手动添加', 'Add manually');
  String get chooseFromGallery => _t('从相册选择', 'Choose from gallery');
  String get scanQrCode => _t('扫描二维码', 'Scan QR code');
  String get selectInstancesToDelete =>
      _t('请先选择要删除的实例', 'Select instances to delete first');
  String get deleteSelectedInstancesTitle =>
      _t('删除选中实例', 'Delete selected instances');
  String deleteSelectedConfirm(int count) {
    if (_isChinese) {
      return '确定删除选中的 $count 个实例及其本地登录信息吗？';
    }
    return count == 1
        ? 'Delete the selected instance and its local login credentials?'
        : 'Delete the selected $count instances and their local login '
              'credentials?';
  }

  String deletedInstances(int count) =>
      _t('已删除 $count 个实例', 'Deleted ${_instances(count)}');
  String deleteFailed(String detail) =>
      _t('删除失败：$detail', 'Failed to delete: $detail');
  String get selectInstancesToExport =>
      _t('请先选择要导出的实例', 'Select instances to export first');
  String get noInstancesToExport => _t('没有可导出的实例', 'No instances to export');
  String exportedSelectedToClipboard(int count) => _t(
    '已导出选中的 $count 个实例到剪贴板（Base64 编码，非加密）',
    'Exported ${_selectedInstances(count)} to the clipboard '
        '(Base64 encoded, not encrypted).',
  );
  String exportedAllToClipboard(int count) => _t(
    '已导出 $count 个实例到剪贴板（Base64 编码，非加密）',
    'Exported ${_instances(count)} to the clipboard '
        '(Base64 encoded, not encrypted).',
  );
  String exportedInstanceToClipboard(String name) => _t(
    '已导出「$name」到剪贴板（Base64 编码，非加密）',
    'Exported “$name” to the clipboard (Base64 encoded, not encrypted).',
  );
  String exportFailed(String detail) =>
      _t('导出失败：$detail', 'Failed to export: $detail');
  String selectedInstancesQrDescription(int count) => _isChinese
      ? '选中的实例（$count 个）'
      : count == 1
      ? 'Selected instance (1)'
      : 'Selected instances ($count)';
  String allInstancesQrDescription(int count) => _isChinese
      ? '全部实例（$count 个）'
      : count == 1
      ? 'All instances (1)'
      : 'All instances ($count)';
  String instanceQrDescription(String name) =>
      _t('实例「$name」', 'Instance “$name”');
  String qrGenerateFailed(String detail) =>
      _t('生成二维码失败：$detail', 'Failed to generate QR code: $detail');
  String readClipboardFailed(String detail) =>
      _t('读取剪贴板失败：$detail', 'Failed to read clipboard: $detail');
  String get clipboardEmpty =>
      _t('剪贴板中没有配置内容', 'No configuration found in the clipboard');
  String selectImageFailed(String detail) =>
      _t('选择图片失败：$detail', 'Failed to select image: $detail');
  String recognizeQrFailed(String detail) =>
      _t('识别二维码失败：$detail', 'Failed to recognize QR code: $detail');
  String get noQrInImage => _t('图片中没有识别到二维码', 'No QR code found in the image');
  String get importQrConfigTitle => _t('导入二维码配置', 'Import QR configuration');
  String get importFromClipboardTitle => _t('从剪贴板导入', 'Import from clipboard');
  String importFailed(String detail) =>
      _t('导入失败：$detail', 'Failed to import: $detail');
  String importConfirm(int count) => _isChinese
      ? '将导入 $count 个实例；相同地址的实例会被更新，是否继续？'
      : 'Import ${_instances(count)}? Instances with the same address will be '
            'updated.';
  String get importAction => _t('导入', 'Import');
  String importedInstances(int count) =>
      _t('已导入 $count 个实例', 'Imported ${_instances(count)}');
  String get deleteInstanceTitle => _t('删除实例', 'Delete instance');
  String deleteInstanceConfirm(String name) => _t(
    '确定删除「$name」及其本地登录信息吗？',
    'Delete “$name” and its local login credentials?',
  );
  String get autoLoginTag => _t('自动登录', 'Auto-login');
  String get editAction => _t('编辑', 'Edit');
  String get moreActions => _t('更多操作', 'More actions');

  // Instance editor.
  String get editInstanceTitle => _t('编辑实例', 'Edit instance');
  String get addInstanceTitle => _t('添加实例', 'Add instance');
  String get editInstanceDescription => _t(
    '修改实例名称、WebUI 地址和登录设置。',
    'Edit the instance name, WebUI address, and login settings.',
  );
  String get addInstanceDescription => _t(
    '添加一个 OlivOS WebUI 实例；自动登录会把密码保存到系统安全存储。',
    'Add an OlivOS WebUI instance. Auto-login stores the password in the '
        'system secure storage.',
  );
  String get nameOptionalLabel => _t('名称（可选）', 'Name (optional)');
  String get nameHint => _t('例如：家里主实例', 'e.g. Home instance');
  String get webUiAddressLabel => _t('WebUI 地址', 'WebUI address');
  String get webUiPasswordLabel => _t('WebUI 密码', 'WebUI password');
  String get passwordKeepCurrentHelper =>
      _t('留空则保留当前密码', 'Leave blank to keep the current password');
  String get passwordSecureHelper =>
      _t('自动登录时保存到系统安全存储', 'Stored in secure storage for auto-login');
  String get autoLoginTitle => _t('自动登录', 'Auto-login');
  String get autoLoginSubtitle =>
      _t('启动时预登录并注入登录凭据', 'Pre-login at startup and inject credentials');
  String get invalidUrlError => _t(
    '请输入有效地址，例如 http://192.168.1.10:20480',
    'Enter a valid address, for example http://192.168.1.10:20480',
  );
  String get autoLoginPasswordRequiredError => _t(
    '勾选自动登录时请填写密码，或关闭自动登录',
    'Enter a password for auto-login, or turn auto-login off',
  );
  String saveFailed(String detail) =>
      _t('保存失败：$detail', 'Failed to save: $detail');

  // QR dialog and scanner.
  String get qrTooLargeTitle => _t('无法生成二维码', 'Unable to generate QR code');
  String get qrTooLargeMessage => _t(
    '配置内容超过二维码容量。请改用“导出到剪贴板”，或减少实例数量后重试。',
    'The configuration exceeds the QR code capacity. Use “Export to '
        'clipboard” instead, or reduce the number of instances and try again.',
  );
  String get qrSaved => _t('二维码已保存', 'QR code saved');
  String qrSaveFailed(String detail) =>
      _t('保存二维码失败：$detail', 'Failed to save QR code: $detail');
  String get qrExportTitle => _t('导出二维码', 'Export QR code');
  String get qrSemanticsLabel =>
      _t('实例配置二维码', 'Instance configuration QR code');
  String get qrScanInstruction => _t(
    '用 OlivOS Companion 手机端扫描此二维码导入配置。',
    'Scan this QR code with OlivOS Companion on your phone to import the '
        'configuration.',
  );
  String get qrSecretWarning => _t(
    '二维码包含自动登录密码，请仅用于自己的设备。',
    'The QR code contains auto-login passwords. Use it only on your own '
        'devices.',
  );
  String get qrSaveLocally => _t('保存到本地', 'Save locally');
  String get qrScannerTitle => _t('扫描二维码', 'Scan QR code');
  String get qrScannerInstruction => _t(
    '将 OlivOS Companion 导出的二维码放入框内',
    'Place a QR code exported from OlivOS Companion inside the frame',
  );
  String get qrCameraError => _t(
    '无法打开相机，请检查相机权限后重试。',
    'Unable to open the camera. Check camera permissions and try again.',
  );
  String get pngImageFileType => _t('PNG 图片', 'PNG image');

  // WebView.
  String autoLoginFailed(String detail) {
    final normalized = detail.trim();
    if (_isChinese) {
      final separator =
          normalized.endsWith('。') ||
              normalized.endsWith('！') ||
              normalized.endsWith('？') ||
              normalized.endsWith('.') ||
              normalized.endsWith('!') ||
              normalized.endsWith('?')
          ? ''
          : '。';
      return '自动登录失败：$normalized$separator已回退到 WebUI 登录页。';
    }
    final separator =
        normalized.endsWith('.') ||
            normalized.endsWith('!') ||
            normalized.endsWith('?')
        ? ''
        : '.';
    return 'Auto-login failed: $normalized$separator '
        'Falling back to the WebUI login page.';
  }

  String pageLoadFailed(String detail) =>
      _t('页面加载失败：$detail', 'Failed to load page: $detail');
  String get back => _t('返回', 'Back');
  String get refresh => _t('刷新', 'Refresh');

  // Startup.
  String get startupAnimationLabel =>
      _t('OlivOS Companion 启动动画', 'OlivOS Companion launch animation');

  // Easter egg.
  String easterEggTapsRemaining(int remaining) {
    if (!_isChinese) {
      return switch (remaining) {
        5 => '5 taps to go',
        4 => 'Developer mode is warming up — 4 taps to go',
        3 => 'lunzhiPenxil is counting behind the door — 3 taps to go',
        2 =>
          'If you have friends who know your heart, '
              'distance cannot keep you apart. 2 taps to go',
        1 => 'The Sword Pass, steep and sheer. 1 tap to go',
        _ => '$remaining taps to go',
      };
    }
    return switch (remaining) {
      5 => '还差 5 次',
      4 => '开发者模式正在热身，还差 4 次',
      3 => '仑质在门后数数，还差 3 次',
      2 => '海内存知己，天涯若比邻。还差 2 次',
      1 => '剑阁峥嵘而崔嵬，还差 1 次',
      _ => '还差 $remaining 次',
    };
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'zh' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
