# Visual Studio 原生开发

Flutter 的 Windows runner 是 C++/CMake 工程，可以用 Visual Studio 打开生成的解决方案，进行 runner 和插件的原生调试。

## 前置条件

- Visual Studio，安装「使用 C++ 的桌面开发」工作负载
- Flutter 3.50.1 与 `DEV_ROOT` 环境（见 `docs/dev-environment.md`）
- Windows Developer Mode（Flutter 插件需要符号链接）
- `flutter_inappwebview_windows` 需要 NuGet CLI 在 `PATH` 中

## 生成并打开解决方案

PowerShell（仓库根目录）：

```powershell
$env:DEV_ROOT = '<你的非系统盘开发目录>'
. .\tools\env.ps1
.\tools\open-vs.ps1
```

常用参数：

```powershell
.\tools\open-vs.ps1 -Configuration Release
.\tools\open-vs.ps1 -NoOpen        # 只生成解决方案并输出路径
.\tools\open-vs.ps1 -NoConfigure   # 假定解决方案已存在，直接打开
```

脚本会：

1. `flutter pub get`
2. `flutter build windows --<debug|profile|release> --config-only`
3. 在 `build/windows/x64/` 查找生成的 `.slnx` 或 `.sln`
4. 用 Visual Studio 打开

生成的解决方案在 `build/` 下，已被 `.gitignore` 忽略，不要提交。不同 Visual Studio 版本可能生成 `.slnx` 或 `.sln`，脚本会自动查找。

## 在 Visual Studio 中

- CMake 会把 `olivos_companion` 设为启动项目，并把调试工作目录设为可执行文件目录。
- F5 构建并启动 runner。
- Visual Studio 适合调试 Windows runner、插件和 C++ 代码。

## Dart 代码

Visual Studio 不会接管 Dart 调试。修改 Dart 代码或 `pubspec` 后：

```powershell
flutter build windows --debug
```

再在 Visual Studio 中构建/调试。Dart 代码的断点、热重载仍使用 VS Code / Flutter DevTools / `flutter run`。

## 重新生成

依赖、CMake 或插件变化后，重新运行：

```powershell
.\tools\open-vs.ps1 -NoOpen
```

或手动：

```powershell
flutter pub get
flutter build windows --debug --config-only
```
