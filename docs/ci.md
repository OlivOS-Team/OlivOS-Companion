# CI 与构建

正式构建统一由 GitHub Actions 完成。本地只跑 `dart format`、`flutter analyze`、`flutter test`，避免本地平台构建和系统盘占用。

## 工作流

| 工作流 | 触发 | Runner | 产物 |
| --- | --- | --- | --- |
| `ci.yml` | push main、PR、手动 | ubuntu-latest | format/analyze/test 结果 |
| `build-android.yml` | push main、tag `v*`、手动 | ubuntu-latest | debug APK（main）/ release APK（tag） |
| `build-windows.yml` | push main、tag `v*`、手动 | windows-latest | Windows Release 目录打包 zip |

macOS/iOS 工作流在后续里程碑接入（macOS runner），首期 iOS 构建使用 `--no-codesign`。

## 触发与成本

- PR 与 main 只跑轻量检查和 Android/Windows 构建。
- macOS/iOS runner 计费约为 Linux 的 10 倍，后续只在 main/tag/手动触发。
- 同一分支的构建使用 concurrency 自动取消旧任务。

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
- Windows：未签名 zip；后续接代码签名。
- macOS：ad-hoc 或未签名 dmg。
- iOS：`flutter build ios --no-codesign`，只出未签名包/模拟器包。

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
