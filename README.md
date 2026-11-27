# OlivOS Companion

OlivOS 多实例 WebUI 客户端。

## 下载

从 [GitHub Releases](https://github.com/OlivOS-Team/OlivOS-Companion/releases) 获取：

- **Windows 安装版（推荐）**：`olivos-companion-windows-setup-x64.exe`
  - 安装到 `Program Files`，创建开始菜单快捷方式，并检测/安装 VC++ 运行库。
  - 启动时可选择简体中文或 English；两种语言显示对应语言的 AGPLv3 文本。
- **Windows 便携版**：`olivos-companion-windows-portable-x64.zip`
  - 解压即可运行，不写入安装目录；目标机器仍需 VC++ 2015-2022 x64 和 WebView2 Runtime。
- Android、macOS、iOS 产物见 Releases 页面。
- Android 覆盖升级要求 APK 使用同一签名。历史测试包使用 CI 临时 debug 签名，
  如果提示“与已安装应用签名不同”，需要先卸载旧版一次；启用固定 release 签名后，
  后续版本可以正常覆盖升级。

Windows 安装包目前未签名，SmartScreen 可能提示；如介意可自行校验 Releases 中每个产物旁的 `.sha256` 文件。

## 许可证

本项目使用 GNU Affero General Public License v3（AGPL-3.0）。

安装器的中文界面展示的是基于开放原子开源基金会「源译识」项目整理的中英双语参考译文；该译文为非官方译文，不具法律效力，以英文原文为准：

- 参考译文来源：<https://legal.openatom.tech/zones/licenses/article/mJh21bfxVv6>
- 英文原文：<https://www.gnu.org/licenses/agpl-3.0.en.html>

## 使用

- 在 Windows 桌面端按 `F11` 切换无边框全屏，再按一次恢复原窗口状态。
- 右上角按钮切换应用亮/暗模式，并同步窗口标题栏、Android 状态栏/导航栏和随后打开的 OlivOS WebUI。
- 在 WebUI 内切换主题时，也会同步回应用的主题和原生窗口外观。
- 实例打开后会自动读取并缓存 OlivOS 版本，实例卡片显示为 `名称 · 版本号 - 版本名称`。
- 右上角可以从剪贴板导入配置或导出全部实例；实例卡片的菜单可以编辑、导出或删除单个实例。
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
