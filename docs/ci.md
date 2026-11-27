# CI 与构建

正式构建由单个 GitHub Actions 工作流 `.github/workflows/build.yml` 完成（对齐 OlivOS 的 Build 结构）。本地只跑 `dart format`、`flutter analyze`、`flutter test`，避免本地平台构建和系统盘占用。

## 工作流

`Build` 工作流包含：

| Job ID | 显示名称 | Runner | 内容 |
| --- | --- | --- | --- |
| `validate` | Validate, test and coverage | ubuntu-latest | `flutter pub get`、格式检查、`flutter analyze`、`flutter test --coverage`、覆盖率报告 |
| `build-android` | Build Android | ubuntu-latest | 已配置签名时构建 release APK；未配置签名的非 tag 构建为 debug APK |
| `build-windows` | Build Windows | windows-latest | Windows Release 便携目录 + Inno Setup 安装包，分两个 artifact 上传 |
| `build-macos` | Build macOS | macos-latest | macOS Release `.app` 打包 |
| `build-ios` | Build iOS (unsigned) | macos-latest | `flutter build ios --no-codesign` 未签名包 |
| `release-draft` | Release draft | ubuntu-latest | tag 触发，仅汇总发布文件并创建 GitHub Release 草稿 |

四个平台构建都依赖 `validate` 通过，彼此独立并行执行；`release-draft` 依赖 `validate` 和四平台构建全部成功。

Job ID 用于 `needs` 和 Actions API；显示名称用于 Actions 页面。artifact 名称独立于 Job ID，例如 `build-android` 上传的 artifact 仍叫 `android`。

## 触发

- push `main`
- push tag `v*`
- pull request
- 手动 `workflow_dispatch`

同一 ref 的旧运行会被 concurrency 自动取消。

## Actions artifacts

- `android`：`olivos-companion-android-release.apk`（配置签名后，包括所有 tag 构建）或 `olivos-companion-android-debug.apk`（未配置签名的非 tag 构建）
- `windows-portable`：未压缩的便携目录，包含 `portable.flag`；Release 阶段才压缩成 zip
- `windows-installer`：`olivos-companion-windows-setup-x64.exe`
- `macos`：`olivos-companion-macos.zip`
- `ios`：`olivos-companion-ios.zip`（未签名）
- `coverage`：`coverage/lcov.info`、JSON、Markdown 和 HTML 报告；仅用于 Actions，不进入 Release

GitHub Actions 下载 artifact 时仍会由平台统一包一层 zip；便携版本身不再预压缩，因此不会出现“zip 套 zip”。

## Release assets

tag 触发时，`release-draft` 只暂存以下发布文件，覆盖率报告不会作为 Release asset 上传：

- `olivos-companion-android-release.apk`
- `olivos-companion-windows-portable-x64.zip`（在 Release 阶段由便携目录生成）
- `olivos-companion-windows-setup-x64.exe`
- `olivos-companion-macos.zip`
- `olivos-companion-ios.zip`
- 每个文件对应的独立 `*.sha256` 校验文件，不再生成合并的 `SHA256SUMS`

## 测试覆盖率

- `validate` 使用 `flutter test --coverage` 生成 `coverage/lcov.info`
- CI 安装 `lcov`，生成 HTML 报告到 `test-results/html`
- `tools/coverage/coverage_summary.py` 生成 JSON 和 Markdown 覆盖率摘要
- Markdown 摘要会写入 GitHub Actions 的 Job Summary
- `coverage` artifact 包含 lcov、JSON、Markdown 和 HTML 报告
- 覆盖率仅作为 Actions artifact 保留，不会上传到 GitHub Release
- Flutter 当前的 lcov 报告通常只有行覆盖率，没有分支数据；统计脚本会明确显示这一点

本地生成：

```bash
flutter test --coverage
python3 tools/coverage/coverage_summary.py coverage/lcov.info \
  --json test-results/coverage.json \
  --markdown test-results/coverage-summary.md
```

## Windows 安装版

- 由 Inno Setup 6 生成；CI 会自动安装 Inno Setup，并下载 Microsoft Visual C++
  2015-2022 x64 运行库到 `windows/installer/redist/`（该目录不入库）。
- 便携目录和安装包分别作为 `windows-portable`、`windows-installer` artifact 上传；
  便携 zip 只在 Release 阶段生成，避免嵌套压缩包。
- 每个发布产物生成同名的独立 `.sha256` 校验文件，不再生成合并的 `SHA256SUMS`。
- 启动时提供简体中文 / English 语言选择；中文界面显示 AGPLv3 中英双语参考译文，
  英文界面显示项目根目录的英文 `LICENSE`。
- 中文参考译文来自开放原子开源基金会「源译识」项目，文件位于
  `windows/installer/license/AGPL-3.0-zh-CN.txt`；译文为非官方参考，以英文原文为准。
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
  /DMyAppVersion=0.1.6 `
  /DMyAppVersionNumeric=0.1.6 `
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

## Android 签名

项目使用 AGP 9.3.3 或更高版本。AGP 9.3.0/9.3.1 的 lint 在 JDK 17 下会因
`java.util.List.removeLast()` 崩溃（Google issue 522845800），不要降级到这两个版本。

Android 要求覆盖安装的新 APK 与已安装版本使用同一签名证书。CI 必须使用固定的
release keystore；如果继续使用 runner 每次临时生成的 debug keystore，不同构建的
APK 签名不同，系统会报 `INSTALL_FAILED_UPDATE_INCOMPATIBLE`（安装失败 -7）。

### 1. 生成 release keystore（只需一次）

在仓库外或已被忽略的路径生成并妥善备份：

```bash
keytool -genkeypair -v \
  -keystore android/app/olivos-release.jks \
  -alias olivos \
  -keyalg RSA -keysize 4096 -validity 10000
```

`android/app/*.jks` 和 `android/key.properties` 已被 `.gitignore` 忽略，绝对不能提交。
密码建议使用较长的安全随机字符串；如果 key 密码与 store 密码不同，请分别记录。

### 2. 写入 GitHub Secrets

将 keystore 转为 Base64：

```powershell
# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/olivos-release.jks")) |
  Set-Content android-keystore.b64 -Encoding ascii
```

```bash
# Linux / macOS
base64 -w0 android/app/olivos-release.jks > android-keystore.b64
```

在 GitHub 仓库的 Settings → Secrets and variables → Actions 中添加：

- `ANDROID_KEYSTORE_BASE64`：`android-keystore.b64` 的完整内容
- `ANDROID_KEY_ALIAS`：上面命令中的 `olivos`
- `ANDROID_KEY_PASSWORD`：key 密码
- `ANDROID_STORE_PASSWORD`：keystore 密码

设置完成后删除本地的 `android-keystore.b64`。这些值只放 Secrets，绝不入库。

### 3. CI 行为

- 四项 Secrets 齐全时，CI 解码 keystore 并生成 `android/key.properties`，构建
  `olivos-companion-android-release.apk`；非 tag 构建和 tag 构建都使用同一签名。
- tag 构建缺少签名 Secrets 会直接失败，避免发布无法升级的 APK。
- 未配置签名的非 tag 构建（例如 PR）回退到 debug 签名并给出 warning，仅用于测试。

### 4. 本地 release 构建

复制 `android/key.properties.example` 为 `android/key.properties`，填入 keystore
路径和密码，然后执行 `flutter build apk --release`。`storeFile` 使用绝对路径和
正斜杠（如 `D:/secure/olivos-release.jks`），避免 Windows 反斜杠被 Java
properties 当作转义字符。

### 5. 升级注意

历史版本使用 CI runner 的临时 debug keystore 签名，和新的固定 release key 不同，
因此第一次切换到固定签名时无法覆盖安装，需要卸载旧版一次（会清除该应用的本地
数据）。从这次固定签名开始，后续版本只要 `applicationId` 和签名 keystore 不变，
就可以正常覆盖升级。不要更换 `applicationId`，也不要丢失 keystore。

## 其他平台

- Windows：未签名的便携 zip 和安装包；后续接代码签名。
- macOS：ad-hoc 或未签名 zip。
- iOS：`--no-codesign`，只出未签名包。
- Apple 证书、描述文件、Team ID 后续接入。

## 本地复现（仅排查 CI 问题时）

```bash
flutter pub get
flutter analyze
flutter test
```

平台构建只在 CI 无法复现且维护者同意时本地执行；执行前确保相关 SDK 位于开发者配置的非系统盘目录。
