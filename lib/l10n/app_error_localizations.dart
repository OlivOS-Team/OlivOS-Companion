import '../data/auth_service.dart';
import '../data/config_transfer.dart';
import 'app_localizations.dart';

extension AppErrorLocalizations on AppLocalizations {
  String authFailureMessage(AuthFailure failure, {int? statusCode}) {
    final isChinese = locale.languageCode == 'zh';
    return switch (failure) {
      AuthFailure.malformedResponse =>
        isChinese ? '登录响应格式不正确' : 'The login response was invalid.',
      AuthFailure.invalidCredentials =>
        isChinese
            ? '密码不正确或登录凭据已失效'
            : 'Incorrect password or expired login credentials.',
      AuthFailure.rateLimited =>
        isChinese
            ? '尝试次数过多，请稍后再试'
            : 'Too many attempts. Please try again later.',
      AuthFailure.httpError =>
        isChinese
            ? '登录失败（HTTP ${statusCode ?? '?'}）'
            : 'Login failed (HTTP ${statusCode ?? '?'}).',
    };
  }

  String configTransferFailureMessage(
    ConfigTransferFailure failure, {
    String? detail,
  }) {
    final isChinese = locale.languageCode == 'zh';
    return switch (failure) {
      ConfigTransferFailure.invalidInstanceUrl =>
        isChinese
            ? '配置中的实例地址无效'
            : 'The instance address in the configuration is invalid.',
      ConfigTransferFailure.malformedInstanceUrl =>
        isChinese
            ? '实例地址无效：${detail ?? ''}'
            : 'Invalid instance address: ${detail ?? ''}',
      ConfigTransferFailure.notCompanionConfig =>
        isChinese
            ? '不是 OlivOS Companion 配置'
            : 'This is not an OlivOS Companion configuration.',
      ConfigTransferFailure.emptyContent =>
        isChinese ? '配置内容为空' : 'The configuration is empty.',
      ConfigTransferFailure.corruptedContent =>
        isChinese
            ? '配置内容损坏或编码不正确'
            : 'The configuration is damaged or incorrectly encoded.',
      ConfigTransferFailure.invalidFormat =>
        isChinese ? '配置格式不正确' : 'The configuration format is invalid.',
      ConfigTransferFailure.unsupportedVersion =>
        isChinese ? '配置版本不受支持' : 'The configuration version is not supported.',
      ConfigTransferFailure.noInstances =>
        isChinese ? '配置中没有实例' : 'The configuration contains no instances.',
      ConfigTransferFailure.invalidInstanceFormat =>
        isChinese
            ? '配置中的实例格式不正确'
            : 'An instance in the configuration has an invalid format.',
    };
  }
}
