# CI 与构建

正式构建由单个 GitHub Actions 工作流 `.github/workflows/build.yml` 完成（对齐 OlivOS 的 Build 结构）。本地只跑 `dart format`、`flutter analyze`、`flutter test`，避免本地平台构建和系统盘占用。

## 工作流

`Build` 工作流包含：

| Job | Runner | 内容 |
| --- | --- | --- |
| `validate` | ubuntu-latest | `flutter pub get`、格式检查、`flutter analyze`、`flutter test` |
| `android` | ubuntu-latest | debug APK（非 tag）/ release APK（tag） |
| `windows` | windows-latest | Windows Release 便携 zip + Inno Setup 安装包 |
| `macos` | macos-latest | macOS Release `.app` 打包 |
| `ios` | macos-latest | `flutter build ios --no-codesign` 未签名包 |
| `release-draft` | ubuntu-latest | tag 触发，汇总四平台 artifacts 创建 GitHub Release 草稿 |

四平台构建都依赖 `validate` 通过；`release-draft` 依赖四平台构建全部成功。

## 触发

- push `main`
- push tag `v*`
- pull request
- 手动 `workflow_dispatch`

同一 ref 的旧运行会被 concurrency 自动取消。

## 产物

- Android：`olivos-companion-android-debug.apk`（非 tag）或 `olivos-companion-android-release.apk`（tag）
- Windows 便携版：`olivos-companion-windows-portable-x64.zip`
- Windows 安装版：`olivos-companion-windows-setup-x64.exe`
- Windows 校验：`olivos-companion-windows-SHA256SUMS.txt`
- macOS：`olivos-companion-macos.zip`
- iOS：`olivos-companion-ios.zip`（未签名）
- tag：以上产物全部附加到 GitHub Release 草稿

## Windows 安装版

- 由 Inno Setup 6 生成；CI 会自动安装 Inno Setup，并下载 Microsoft Visual C++
  2015-2022 x64 运行库到 `windows/installer/redist/`（该目录不入库）。
- 默认安装到 `Program Files\OlivOS Companion`，需要管理员权限；创建开始菜单
  快捷方式，桌面快捷方式可选，并带卸载程序。
- 安装时检测 VC++ 运行库，缺失时静默安装；卸载不会删除用户实例和登录信息。
- 便携版不会安装运行库，目标机器仍需 VC++ 2015-2022 x64 运行库。
- 安装包使用 AppData/LocalAppData 保存数据；便携包包含 `portable.flag`，数据保存在
  exe 同目录的 `userdata` 中，WebView2 profile 也跟随该目录。
- WebView2 Runtime 是运行前置条件：Windows 11 通常已内置，Windows 10 可能需要
  单独安装。
- 安装包当前未签名，Windows SmartScreen 可能提示；正式分发前接入代码签名。

本地验证安装包（仅 Windows 维护者）：

```powershell
# 安装 Inno Setup 6，并把 VC++ 运行库放到 windows\installer\redist\
# 名称必须是 vc_redist.x64.exe
& "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe" `
  /DMyAppVersion=0.1.2 `
  /DMyAppVersionNumeric=0.1.2 `
  windows\installer\olivos-companion.iss
```

输出为 `dist\olivos-companion-windows-setup-x64.exe`。

## 下载产物

使用 `gh`，并指定本地 artifacts 目录（建议放在非系统盘）：

```powershell
gh run list --limit 10
gh run download <run-id> --dir <artifacts-dir>\olivos-companion
```

或从 GitHub Actions 页面下载。建议把产物放在项目缓存或 `DEV_ROOT` 下，避免占用系统盘。

## 读取失败日志

```powershell
gh run view <run-id> --log-failed
```

排查 CI 编译/链接/平台配置问题时使用该命令；本地不执行平台构建。

## 签名

首期侧载/内测：

- Android：debug 或 unsigned release。
- Windows：未签名的便携 zip 和安装包；后续接代码签名。
- macOS：ad-hoc 或未签名 zip。
- iOS：`--no-codesign`，只出未签名包。

正式签名材料放 GitHub Secrets，绝不入库：

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`
- Apple 证书、描述文件、Team ID 后续接入。

## 本地复现（仅排查 CI 问题时）

```bash
flutter pub get
flutter analyze
flutter test
```

平台构建只在 CI 无法复现且维护者同意时本地执行；执行前确保相关 SDK 位于开发者配置的非系统盘目录。
