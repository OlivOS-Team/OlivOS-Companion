#!/usr/bin/env bash
# OlivOS Companion 开发环境（Git Bash）
# 用法：
#   export DEV_ROOT=/path/to/dev
#   source tools/env.sh
# 仓库不写死盘符；所有工具与缓存都放在 DEV_ROOT 下。

if [ -z "${DEV_ROOT:-}" ]; then
  echo "请先设置 DEV_ROOT，指向非系统盘上的开发目录。" >&2
  return 1 2>/dev/null || exit 1
fi

if command -v cygpath >/dev/null 2>&1; then
  DEV_ROOT_POSIX="$(cygpath -u "$DEV_ROOT")"
  DEV_ROOT_WIN="$(cygpath -m "$DEV_ROOT")"
else
  DEV_ROOT_POSIX="$DEV_ROOT"
  DEV_ROOT_WIN="$DEV_ROOT"
fi

export FLUTTER_HOME="$DEV_ROOT_POSIX/flutter"
export PUB_CACHE="$DEV_ROOT_WIN/cache/pub"
export TMP="$DEV_ROOT_WIN/cache/tmp"
export TEMP="$TMP"
export PATH="$DEV_ROOT_POSIX/nuget:$FLUTTER_HOME/bin:$PATH"

# 仅在确需本地 Android/Windows 构建时取消注释（默认不启用，构建走 CI）
# export JAVA_HOME="$DEV_ROOT_WIN/jdk-17"
# export ANDROID_SDK_ROOT="$DEV_ROOT_WIN/android-sdk"
# export ANDROID_HOME="$ANDROID_SDK_ROOT"
# export ANDROID_USER_HOME="$DEV_ROOT_WIN/android"
# export GRADLE_USER_HOME="$DEV_ROOT_WIN/cache/gradle"

echo "DEV_ROOT     = $DEV_ROOT"
echo "FLUTTER_HOME = $FLUTTER_HOME"
echo "PUB_CACHE    = $PUB_CACHE"
echo "TMP          = $TMP"
