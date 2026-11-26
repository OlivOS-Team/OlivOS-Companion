# OlivOS Companion

OlivOS 多实例 WebUI 客户端。

## 下载

从 [GitHub Releases](https://github.com/OlivOS-Team/OlivOS-Companion/releases) 获取：

- **Windows 安装版（推荐）**：`olivos-companion-windows-setup-x64.exe`
  - 安装到 `Program Files`，创建开始菜单快捷方式，并检测/安装 VC++ 运行库。
- **Windows 便携版**：`olivos-companion-windows-portable-x64.zip`
  - 解压即可运行，不写入安装目录；目标机器仍需 VC++ 2015-2022 x64 和 WebView2 Runtime。
- Android、macOS、iOS 产物见 Releases 页面。

Windows 安装包目前未签名，SmartScreen 可能提示；如介意可自行校验 Releases 中的 SHA-256 文件。

## 使用

- 在 Windows 桌面端按 `F11` 切换无边框全屏，再按一次恢复原窗口状态。
- 实例打开后会自动读取并缓存 OlivOS 版本，实例卡片显示为 `名称 · 版本号 - 版本名称`。
