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
- 右上角按钮切换应用亮/暗模式，并同步到随后打开的 OlivOS WebUI。
- 实例打开后会自动读取并缓存 OlivOS 版本，实例卡片显示为 `名称 · 版本号 - 版本名称`。
- 右上角可以从剪贴板导入配置或导出全部实例；实例卡片的菜单可以导出单个实例。
- 导出格式为 `olivoscompanionconf://` 加 Base64 编码的配置，导入时相同地址的实例会更新，新地址会新增。
- Base64 不是加密，导出内容包含自动登录密码；不要把剪贴板配置发给不可信的人。

## 数据位置

- **安装版**：
  - 实例、版本缓存和登录信息：`%APPDATA%\com.olivosteam\olivos_companion`
  - WebView2 profile：`%LOCALAPPDATA%\com.olivosteam\olivos_companion\WebView2`
- **便携版**：
  - 数据跟随 exe，存放在 exe 同目录的 `userdata` 中
  - 便携包根目录包含 `portable.flag`，应用据此切换到便携模式
- 自动登录密码使用 Windows DPAPI 加密，和当前 Windows 用户绑定；把便携目录复制到其他用户或其他电脑后，需要重新输入密码。
- 升级到新版本时，旧的 `shared_preferences.json` 会自动迁移为 `instances.json`；WebView2 profile 会切换到新位置，首次打开实例可能需要重新登录 WebUI。
