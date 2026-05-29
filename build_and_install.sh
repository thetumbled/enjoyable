#!/bin/bash
#
# 编译 Enjoyable（含 产品名+VID+PID 设备 UID 补丁）并安装到 /Applications
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SCHEME="Enjoyable"
CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_DIR="$ROOT/build"
APP_NAME="Enjoyable.app"
INSTALL_PATH="/Applications/$APP_NAME"

if ! xcodebuild -version &>/dev/null; then
    if [[ -d "/Applications/Xcode.app/Contents/Developer" ]]; then
        export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
    else
        echo "错误: 需要完整 Xcode（不是仅 Command Line Tools）。"
        echo "请安装 Xcode 后执行: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
        exit 1
    fi
fi

echo "==> 清理旧构建..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> 编译 ($CONFIGURATION)..."
xcodebuild \
    -project "$ROOT/Enjoyable.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    CONFIGURATION_BUILD_DIR="$BUILD_DIR/Build/Products/$CONFIGURATION" \
    ONLY_ACTIVE_ARCH=YES \
    build

BUILT_APP="$BUILD_DIR/Build/Products/$CONFIGURATION/$APP_NAME"
if [[ ! -d "$BUILT_APP" ]]; then
  BUILT_APP="$(find "$BUILD_DIR" -name "$APP_NAME" -type d | head -1)"
fi

if [[ ! -d "$BUILT_APP" ]]; then
    echo "错误: 未找到编译产物 $APP_NAME"
    exit 1
fi

BINARY="$BUILT_APP/Contents/MacOS/Enjoyable"
if [[ ! -f "$BINARY" ]]; then
    echo "错误: 未生成可执行文件 $BINARY"
    echo "常见原因: 工程 VALID_ARCHS 与当前 Mac 架构不匹配（已在本仓库改为 arm64+x86_64）"
    exit 1
fi
echo "==> 可执行文件: $(file "$BINARY")"

echo "==> 安装到 $INSTALL_PATH ..."
if [[ -d "$INSTALL_PATH" ]]; then
    rm -rf "$INSTALL_PATH"
fi
cp -R "$BUILT_APP" "$INSTALL_PATH"

echo "==> 本地签名（免 Gatekeeper 反复提示）..."
codesign --force --deep --sign - "$INSTALL_PATH" 2>/dev/null || true
xattr -cr "$INSTALL_PATH" 2>/dev/null || true

echo ""
echo "完成: $INSTALL_PATH"
echo ""
echo "首次打开若被拦截: 右键 Enjoyable → 打开"
echo "需在 系统设置 → 隐私与安全性 中授予「辅助功能」和「输入监控」"
echo ""
echo "本构建变更:"
echo "  - 设备 UID = 产品名:VID:PID（换 USB 口仍有效）"
echo "  - 忽略 macOS 虚拟 GamePad-1 节点"
echo "  - 旧版映射需重新配置"
