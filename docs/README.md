# 开发文档

本目录面向开发和维护人员，记录本项目的环境约定、CI/发布流程和平台调试方式。面向用户的下载、功能和数据位置说明请回到根目录的 [README](../README.md)。

## 环境

- [开发环境与磁盘约定](dev-environment.md)：Flutter 版本、`DEV_ROOT`、本地允许/避免的命令、VS Code F5 调试和 macOS 构建注意事项。

## 构建与发布

- [CI 与构建](ci.md)：GitHub Actions 工作流、平台产物、覆盖率、Windows 安装包、Android 签名与 Release 草稿流程。
- [Visual Studio 调试](visual-studio.md)：Windows runner / 原生插件的 C++ 调试方式。

## 数据

- [数据与运行目录](data-layout.md)：实例、设置、密码和 WebView2 profile 的存放位置及迁移行为。
