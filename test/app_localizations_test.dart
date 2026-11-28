import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/data/auth_service.dart';
import 'package:olivos_companion/data/config_transfer.dart';
import 'package:olivos_companion/l10n/app_error_localizations.dart';
import 'package:olivos_companion/l10n/app_localizations.dart';

void main() {
  const zh = AppLocalizations(Locale('zh', 'CN'));
  const en = AppLocalizations(Locale('en'));

  test('关于页中英文案与俄语格言', () {
    expect(zh.aboutTitle, '关于 OlivOS Companion');
    expect(en.aboutTitle, 'About OlivOS Companion');
    expect(zh.aboutMotto, '世界是属于每一个人的。要创造一个充满逻辑并尊重每一个人的世界。');
    expect(en.aboutMotto, startsWith('Мир, принадлежащий всем и каждому'));
    expect(en.aboutMotto, contains('логики и уважения к человеку'));
  });

  test('实例计数使用英文单复数', () {
    expect(zh.selectedCount(1), '已选择 1 个');
    expect(en.selectedCount(1), '1 selected');
    expect(en.selectedCount(2), '2 selected');
    expect(en.instanceCount(1), '1 instance');
    expect(en.instanceCount(2), '2 instances');
    expect(en.deleteSelectedConfirm(1), contains('the selected instance'));
    expect(en.deleteSelectedConfirm(2), contains('2 instances'));
    expect(en.importedInstances(1), 'Imported 1 instance');
    expect(en.importedInstances(2), 'Imported 2 instances');
  });

  test('系统语言解析为简体中文或英文', () {
    expect(
      AppLocalizations.resolveSystemLocale(const [Locale('zh', 'TW')]),
      const Locale('zh', 'CN'),
    );
    expect(
      AppLocalizations.resolveSystemLocale(const [Locale('en', 'US')]),
      const Locale('en'),
    );
    expect(
      AppLocalizations.resolveSystemLocale(const [Locale('fr')]),
      const Locale('en'),
    );
  });

  test('登录错误按错误码本地化', () {
    expect(
      zh.authFailureMessage(AuthFailure.invalidCredentials),
      '密码不正确或登录凭据已失效',
    );
    expect(
      en.authFailureMessage(AuthFailure.rateLimited),
      'Too many attempts. Please try again later.',
    );
    expect(
      en.authFailureMessage(AuthFailure.httpError, statusCode: 500),
      'Login failed (HTTP 500).',
    );
  });

  test('配置导入错误按错误码本地化', () {
    expect(
      zh.configTransferFailureMessage(ConfigTransferFailure.emptyContent),
      '配置内容为空',
    );
    expect(
      en.configTransferFailureMessage(
        ConfigTransferFailure.malformedInstanceUrl,
        detail: 'not-a-url',
      ),
      'Invalid instance address: not-a-url',
    );
    expect(
      en.configTransferFailureMessage(ConfigTransferFailure.noInstances),
      'The configuration contains no instances.',
    );
  });
}
