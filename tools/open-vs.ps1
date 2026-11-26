# 生成并打开 Visual Studio 解决方案
# 用法（仓库根目录，PowerShell）：
#   .\tools\open-vs.ps1
#   .\tools\open-vs.ps1 -Configuration Release
#   .\tools\open-vs.ps1 -NoOpen
#   .\tools\open-vs.ps1 -NoConfigure

param(
    [ValidateSet('Debug', 'Profile', 'Release')]
    [string]$Configuration = 'Debug',
    [switch]$NoConfigure,
    [switch]$NoOpen
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

if (-not $env:FLUTTER_HOME -and $env:DEV_ROOT) {
    $env:FLUTTER_HOME = Join-Path $env:DEV_ROOT 'flutter'
}

$flutter = $null
if ($env:FLUTTER_HOME) {
    $candidate = Join-Path $env:FLUTTER_HOME 'bin\flutter.bat'
    if (Test-Path $candidate) {
        $flutter = $candidate
    }
}
if (-not $flutter) {
    $command = Get-Command flutter -ErrorAction SilentlyContinue
    if ($command) {
        $flutter = $command.Source
    }
}
if (-not $flutter) {
    throw '找不到 Flutter。请设置 FLUTTER_HOME / DEV_ROOT，或把 flutter 加入 PATH。'
}

$mode = $Configuration.ToLowerInvariant()
if (-not $NoConfigure) {
    & $flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw 'flutter pub get 失败。'
    }

    & $flutter build windows "--$mode" --config-only
    if ($LASTEXITCODE -ne 0) {
        throw '生成 Visual Studio 解决方案失败。'
    }
}

$outputDir = Join-Path $repo 'build\windows\x64'
$solution = Get-ChildItem -LiteralPath $outputDir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in @('.sln', '.slnx') } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $solution) {
    throw "未找到生成的 Visual Studio 解决方案。请先运行 flutter build windows --$mode --config-only。"
}

Write-Host "Solution: $($solution.FullName)"
if ($NoOpen) {
    return
}

$vswhere = $null
if (${env:ProgramFiles(x86)}) {
    $candidate = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path $candidate) {
        $vswhere = $candidate
    }
}

$devenv = $null
if ($vswhere) {
    $vsPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($vsPath) {
        $candidate = Join-Path $vsPath 'Common7\IDE\devenv.exe'
        if (Test-Path $candidate) {
            $devenv = $candidate
        }
    }
}

if ($devenv) {
    Start-Process -FilePath $devenv -ArgumentList "`"$($solution.FullName)`""
} else {
    Start-Process -FilePath $solution.FullName
}
