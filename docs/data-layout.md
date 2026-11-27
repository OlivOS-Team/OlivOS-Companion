# 数据与运行目录

应用启动时会先根据是否处于便携模式确定数据目录，之后实例、设置和 WebView2 都围绕该目录工作。实现见 `lib/core/app_paths.dart`。

## 目录

### Windows 安装版

- 实例列表：`%APPDATA%\com.olivosteam\olivos_companion\instances.json`
- 主题设置：`%APPDATA%\com.olivosteam\olivos_companion\settings.json`
- WebView2 profile：`%LOCALAPPDATA%\com.olivosteam\olivos_companion\WebView2`
- 自动登录密码：系统安全存储（Windows DPAPI），不写入 `instances.json`

WebView2 使用 `LocalAppData`，避免把可写 profile 放进只读的安装目录，也避免通过漫游配置同步。

### Windows 便携版

便携版由 exe 同目录的 `portable.flag` 识别：

- 实例与设置：`<exe 目录>\userdata\`
- WebView2 profile：`<exe 目录>\userdata\WebView2`
- 自动登录密码：仍然使用系统安全存储；Windows 上由 DPAPI 绑定当前用户
- 便携版不会执行旧 `SharedPreferences` 数据迁移

把便携目录复制到其他 Windows 用户或其他电脑后，密码需要重新输入。

### Android / iOS / macOS

数据由 `path_provider` 返回的应用支持目录管理；密码通过 `flutter_secure_storage` 使用各平台安全存储。

## 迁移行为

- 实例数据从旧版 `SharedPreferences`（`instances.v1`）迁移到 `instances.json`，仅在非便携模式首次读取时执行。
- 如果 `instances.json` 损坏，会尝试回退到旧 `SharedPreferences` 数据；回退失败则返回空列表，不会覆盖已有文件。
- 主题设置独立存放在 `settings.json`，与实例数据分开。
- WebView2 profile 位置由当前安装模式决定；切换安装版/便携版后，首次打开实例可能需要重新登录 OlivOS WebUI。

## 清理与重置

退出应用后删除对应数据目录即可重置实例和主题设置；删除 WebView2 profile 会同时清除 OlivOS WebUI 的 Cookie 和会话。自动登录密码由系统安全存储管理：Windows 上随数据目录中的安全存储文件删除，Android/iOS/macOS 可能需要在系统钥匙串或凭据设置中清理。
