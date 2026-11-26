# OlivOS Companion 开发环境（当前 PowerShell 会话）
# 用法：
#   $env:DEV_ROOT = '<非系统盘上的开发目录>'
#   . .\tools\env.ps1
# 仓库不写死盘符；所有工具与缓存都放在 DEV_ROOT 下。

if (-not $env:DEV_ROOT) {
    throw "请先设置 DEV_ROOT，指向非系统盘上的开发目录。"
}

$DevRoot = $env:DEV_ROOT
$env:FLUTTER_HOME = Join-Path $DevRoot 'flutter'
$env:PUB_CACHE = Join-Path $DevRoot 'cache\pub'
$env:TMP = Join-Path $DevRoot 'cache\tmp'
$env:TEMP = $env:TMP
$NugetDir = Join-Path $DevRoot 'nuget'
$env:PATH = "$NugetDir;$env:FLUTTER_HOME\bin;$env:PATH"

# 仅在确需本地 Android/Windows 构建时取消注释（默认不启用，构建走 CI）
# $env:JAVA_HOME = Join-Path $DevRoot 'jdk-17'
# $env:ANDROID_SDK_ROOT = Join-Path $DevRoot 'android-sdk'
# $env:ANDROID_HOME = $env:ANDROID_SDK_ROOT
# $env:ANDROID_USER_HOME = Join-Path $DevRoot 'android'
# $env:GRADLE_USER_HOME = Join-Path $DevRoot 'cache\gradle'

Write-Host "DEV_ROOT     = $env:DEV_ROOT"
Write-Host "FLUTTER_HOME = $env:FLUTTER_HOME"
Write-Host "PUB_CACHE    = $env:PUB_CACHE"
Write-Host "TMP          = $env:TMP"
