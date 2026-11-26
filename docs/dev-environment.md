# 开发环境与磁盘约定

本项目默认**不本地构建平台包**，本地只做静态检查与单测；Android/iOS/Windows/macOS 正式构建交给 GitHub Actions。SDK、缓存和构建产物建议放在非系统盘，具体位置由开发者通过 `DEV_ROOT` 指定。

## 版本

- Flutter：3.50.1 stable（项目锁定；CI 使用同一版本）
- Dart：随 Flutter 自带
- Git Bash / PowerShell：二选一
- GitHub CLI（`gh`）：用于读取 Actions 日志、下载 artifacts
- 可选平台工具链：Android SDK + JDK 17、Visual Studio Build Tools、Xcode（仅本地构建/调试时需要）

## 环境变量

由开发者按自己的环境设置，仓库不写死盘符或用户目录：

| 变量 | 说明 |
| --- | --- |
| `DEV_ROOT` | 非系统盘上的开发目录根，例如你选择的 `<DEV_ROOT>` |
| `FLUTTER_HOME` | `<DEV_ROOT>/flutter` |
| `PUB_CACHE` | `<DEV_ROOT>/cache/pub` |
| `TMP` / `TEMP` | 可选：`<DEV_ROOT>/cache/tmp` |
| `PATH` 中的 NuGet | `<DEV_ROOT>/nuget` |

本地 Android/Windows 例外构建时再设置：

- `JAVA_HOME`
- `ANDROID_SDK_ROOT` / `ANDROID_HOME`
- `ANDROID_USER_HOME`
- `GRADLE_USER_HOME`

Xcode、Windows SDK 等受系统限制的组件可能无法完全避开系统盘；这类例外由开发者自行管理。

## 启用环境

PowerShell：

```powershell
$env:DEV_ROOT = '<你的非系统盘开发目录>'
. .\tools\env.ps1
```

Git Bash：

```bash
export DEV_ROOT=/path/to/dev
source tools/env.sh
```

脚本只影响当前终端会话，不修改系统级环境变量。需要长期生效时再自行写入用户环境变量。

## 验证

```bash
flutter --version
flutter doctor -v
```

预期：

- `flutter --version` 显示 3.50.1。
- `flutter doctor` 可能提示缺少 Android SDK / Visual Studio / Xcode；这是预期的，因为本地不构建。
- `PUB_CACHE` 与 `TMP` 指向 `DEV_ROOT` 下的缓存目录。

## 允许的本地命令

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
```

## 避免的本地命令

```bash
flutter build apk
flutter build windows
flutter build macos
flutter build ios
flutter run -d windows
flutter run -d android
```

确需本地构建时，先确认相关 SDK 位于开发者配置的非系统盘目录。

**例外：VS Code F5 调试**。F5 会启动 Windows debug 构建，属于本地调试例外；正式构建仍走 GitHub Actions。

## VS Code 调试

- `.vscode/launch.json`：
  - `OlivOS Companion (Windows)`：F5 默认，`deviceId=windows`
  - `OlivOS Companion (当前设备)`：使用 VS Code 状态栏选中的设备
  - `OlivOS Companion (macOS)`：`deviceId=macos`
- `.vscode/settings.json`：`dart.flutterSdkPath = ${env:FLUTTER_HOME}`，并启用 `dart.flutterHotReloadOnSave = allIfDirty`（保存有改动的文件时自动热重载）。
- 热重载只影响 Dart/Flutter UI；修改原生插件、`pubspec`、平台工程或应用入口初始化逻辑时，需要 Hot Restart、重新构建或重启调试会话。Visual Studio 的原生 F5 不提供 Dart 热重载。
- `.vscode/extensions.json`：推荐 `Dart-Code.flutter` 与 `Dart-Code.dart-code`
- Visual Studio 原生开发（Windows runner / 插件 C++ 调试）见 `docs/visual-studio.md`。
- 需要安装 Dart/Flutter 扩展。
- 需要设置 `FLUTTER_HOME`、`PUB_CACHE`，并确保 NuGet CLI 在 `PATH` 中。
- 设置环境变量后需要**完全退出并重新打开 VS Code**，否则 `${env:FLUTTER_HOME}` 解析不到。
- `.vscode/launch.json` 不包含机器绝对路径；F5 依赖上述用户环境变量。
- **前置条件：Windows Developer Mode 必须开启**。Flutter 插件在 Windows 上需要创建符号链接；未开启时 F5 / 本地 Windows 构建会报 `Building with plugins requires symlink support`。开启路径：Windows 设置 → 系统 → 开发者选项 → 开发人员模式，或运行 `start ms-settings:developers`。
- 如果无法开启 Developer Mode，可临时以管理员身份运行 VS Code（右键 → 以管理员身份运行）再按 F5；这只是绕过符号链接权限，不建议长期使用。
- `flutter_inappwebview_windows` 需要 NuGet CLI；请把 NuGet 目录加入 `PATH` 或 `tools/env.*`。
- 较新的 MSVC 会把 `<experimental/coroutine>` 视为硬错误；`windows/CMakeLists.txt` 已加入 `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS`。插件升级后可移除该兼容宏。
- F5 的 Windows debug 构建使用 `DEV_ROOT` 下的 Flutter SDK 与 pub cache；临时目录默认使用系统值，需要时自行设置用户级 `TMP`/`TEMP`。
- 如果 F5 提示找不到 NuGet，完全退出并重新打开 VS Code，让用户 `PATH` 生效。

## macOS 构建

- `flutter_inappwebview_macos` beta 的 Swift Package 最低声明为 macOS 10.14，但 `AuthenticationServices` 相关 API 需要 10.15+。
- 因此 macOS 构建临时使用 CocoaPods：工作流设置 `FLUTTER_SWIFT_PACKAGE_MANAGER=false`，由 `macos/Podfile` 的 `post_install` 将 pod 部署目标统一提升到 12.0。
- 本地 macOS 构建也需要设置 `FLUTTER_SWIFT_PACKAGE_MANAGER=false`，再执行 `flutter build macos`。
- 插件上游修复后，移除该开关和 Podfile 兼容设置即可恢复 SPM。

## 应用图标

- 母图：`resource/favoricon.ico`（256×256，OlivOS 图标）。
- 重新生成：
  ```bash
  python tools/generate_icons.py
  ```
- 输出：
  - Android：`mipmap-*/ic_launcher.png`（48/72/96/144/192）
  - iOS：`AppIcon.appiconset` 全部尺寸，统一 RGB 无 alpha（App Store 要求）
  - macOS：`AppIcon.appiconset` 16–1024
  - Windows：`windows/runner/resources/app_icon.ico`（16/24/32/48/64/128/256）
- 依赖 Pillow；1024 尺寸由 256 母图放大，若有更高分辨率母图，替换 `resource/favoricon.ico` 后重跑即可。
- 修改图标后需重新构建才会反映到安装包；iOS/macOS 需重新打包。

## 清理

- Flutter SDK 安装包可在验证后删除；具体下载目录由开发者自行管理。
- 如需重置 pub 缓存：删除 `PUB_CACHE` 目录，重新 `flutter pub get`。
- 如需重置临时目录：清空 `TMP` 下内容（确保没有正在运行的构建）。
- 不要删除 `FLUTTER_HOME`，除非准备重新安装。

## 项目约定

- Flutter 3.50 将 Material 拆分为官方 `material_ui` 包，代码导入使用 `package:material_ui/material_ui.dart`。
- 不要在仓库中提交本地 SDK 路径、Drive 盘符、用户名、证书或构建产物；这些由 `.gitignore` 与用户环境变量隔离。
